defmodule CrucibleModelRegistry.Pins.Fetcher do
  @moduledoc "Materializes a pinned artifact bundle through the registry storage layer."

  alias CrucibleModelRegistry.Pins.{ArtifactPin, Receipt, Verifier}
  alias CrucibleModelRegistry.Storage
  alias CrucibleModelRegistry.Storage.Utils

  @type downloader :: (keyword() -> {:ok, Path.t()} | {:error, term()})

  @doc "Fetches every required file in `pin` into `destination` and verifies the result."
  @spec fetch(ArtifactPin.t(), Path.t(), keyword()) :: {:ok, Receipt.t()} | {:error, term()}
  def fetch(%ArtifactPin{} = pin, destination, opts \\ []) when is_list(opts) do
    opts =
      Keyword.validate!(opts,
        downloader: &default_download/1,
        force: false,
        offline_mode: false,
        progress_callback: nil,
        storage_opts: [],
        now: &DateTime.utc_now/0
      )

    destination = Path.expand(destination)
    File.mkdir_p!(destination)

    with {:ok, files} <- fetch_files(pin, destination, opts) do
      {:ok,
       Receipt.new(:fetch, pin, destination, files, created_at: Keyword.fetch!(opts, :now).())}
    end
  rescue
    exception -> {:error, exception}
  end

  @doc "Fetches every required file, raising on failure."
  @spec fetch!(ArtifactPin.t(), Path.t(), keyword()) :: Receipt.t()
  def fetch!(%ArtifactPin{} = pin, destination, opts \\ []) do
    case fetch(pin, destination, opts) do
      {:ok, receipt} -> receipt
      {:error, %_{} = exception} -> raise exception
      {:error, reason} -> raise RuntimeError, "artifact pin fetch failed: #{inspect(reason)}"
    end
  end

  @doc "Default downloader backed by `CrucibleModelRegistry.Storage.download/3`."
  @spec default_download(keyword()) :: {:ok, Path.t()} | {:error, term()}
  def default_download(args) when is_list(args) do
    remote_path = Keyword.fetch!(args, :remote_path)
    cache_path = Keyword.fetch!(args, :cache_path)
    storage_opts = Keyword.get(args, :storage_opts, [])

    case Storage.download(remote_path, cache_path, storage_opts) do
      :ok -> {:ok, cache_path}
      {:error, _reason} = error -> error
    end
  end

  defp fetch_files(pin, destination, opts) do
    Enum.reduce_while(pin.files, {:ok, []}, fn required_file, {:ok, receipts} ->
      case fetch_one(pin, required_file, destination, opts) do
        {:ok, receipt} -> {:cont, {:ok, [receipt | receipts]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, receipts} -> {:ok, Enum.reverse(receipts)}
      {:error, _reason} = error -> error
    end
  end

  defp fetch_one(pin, required_file, destination, opts) do
    if not Keyword.fetch!(opts, :force) and file_verified?(required_file, destination) do
      Verifier.verified_file_receipt(required_file, destination, :skipped)
    else
      do_fetch_one(pin, required_file, destination, opts)
    end
  end

  defp do_fetch_one(pin, required_file, destination, opts) do
    target = Verifier.target_path(destination, required_file.path)
    File.mkdir_p!(Path.dirname(target))

    args =
      [
        repo_id: pin.repo_id,
        revision: pin.revision,
        path: required_file.path,
        filename: required_file.path,
        repo_type: :dataset,
        remote_path: remote_path(pin, required_file.path),
        cache_path: cache_path(destination, required_file.path),
        verify_checksum: true,
        expected_sha256: required_file.sha256,
        offline_mode: Keyword.fetch!(opts, :offline_mode),
        storage_opts: Keyword.fetch!(opts, :storage_opts)
      ]
      |> maybe_add(:progress_callback, Keyword.get(opts, :progress_callback))

    case Keyword.fetch!(opts, :downloader).(args) do
      {:ok, source_path} ->
        with :ok <- copy_verified_source(required_file, source_path, target) do
          Verifier.verified_file_receipt(required_file, destination, :fetched)
        end

      {:error, reason} ->
        {:error, {:download_failed, required_file.path, reason}}
    end
  end

  defp copy_verified_source(required_file, source_path, target) do
    source_sha256 = Utils.checksum(source_path)

    if source_sha256 != required_file.sha256 do
      {:error, {:checksum_mismatch, required_file.path, required_file.sha256, source_sha256}}
    else
      unless Path.expand(source_path) == Path.expand(target) do
        File.cp!(source_path, target)
      end

      :ok
    end
  end

  defp file_verified?(required_file, destination) do
    match?({:ok, _receipt}, Verifier.verified_file_receipt(required_file, destination, :verified))
  end

  defp remote_path(pin, relative_path), do: Path.join([pin.repo_id, pin.revision, relative_path])

  defp cache_path(destination, relative_path) do
    Path.join([destination, ".fetch-cache", relative_path])
  end

  defp maybe_add(args, _key, nil), do: args
  defp maybe_add(args, key, value), do: Keyword.put(args, key, value)
end
