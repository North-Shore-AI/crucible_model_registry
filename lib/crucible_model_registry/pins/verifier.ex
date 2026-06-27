defmodule CrucibleModelRegistry.Pins.Verifier do
  @moduledoc "Verifies a materialized artifact bundle against an artifact pin."

  alias CrucibleModelRegistry.Pins.{ArtifactPin, Receipt}
  alias CrucibleModelRegistry.ProviderCompatibility
  alias CrucibleModelRegistry.Storage.Utils

  @doc "Verifies all files in `pin` exist under `destination` with matching SHA-256 checksums."
  @spec verify(ArtifactPin.t(), Path.t(), keyword()) :: {:ok, Receipt.t()} | {:error, term()}
  def verify(%ArtifactPin{} = pin, destination, opts \\ []) when is_list(opts) do
    destination = Path.expand(destination)

    with {:ok, files} <- verify_files(pin.files, destination),
         {:ok, compatibility} <- verify_compatibility(pin, opts) do
      {:ok,
       Receipt.new(:verify, pin, destination, files,
         created_at: now(opts),
         metadata: receipt_metadata(compatibility)
       )}
    end
  rescue
    exception -> {:error, exception}
  end

  @doc "Verifies all files, raising on the first missing or mismatched file."
  @spec verify!(ArtifactPin.t(), Path.t(), keyword()) :: Receipt.t()
  def verify!(%ArtifactPin{} = pin, destination, opts \\ []) do
    case verify(pin, destination, opts) do
      {:ok, receipt} ->
        receipt

      {:error, %_{} = exception} ->
        raise exception

      {:error, reason} ->
        raise RuntimeError, "artifact pin verification failed: #{inspect(reason)}"
    end
  end

  @doc false
  @spec verified_file_receipt(
          CrucibleModelRegistry.Pins.RequiredFile.t(),
          Path.t(),
          Receipt.file_status()
        ) ::
          {:ok, Receipt.file_receipt()} | {:error, term()}
  def verified_file_receipt(required_file, destination, status) do
    target = target_path(destination, required_file.path)

    if File.exists?(target) do
      actual = Utils.checksum(target)

      if actual == required_file.sha256 do
        {:ok,
         %{
           path: required_file.path,
           sha256: required_file.sha256,
           size_bytes: Utils.size_bytes(target),
           status: status
         }}
      else
        {:error, {:checksum_mismatch, required_file.path, required_file.sha256, actual}}
      end
    else
      {:error, {:missing_required_file, required_file.path}}
    end
  end

  @doc false
  @spec target_path(Path.t(), String.t()) :: Path.t()
  def target_path(destination, relative_path) do
    destination
    |> Path.expand()
    |> Path.join(relative_path)
  end

  defp verify_files(files, destination) do
    Enum.reduce_while(files, {:ok, []}, fn required_file, {:ok, receipts} ->
      case verified_file_receipt(required_file, destination, :verified) do
        {:ok, receipt} -> {:cont, {:ok, [receipt | receipts]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, receipts} -> {:ok, Enum.reverse(receipts)}
      {:error, _reason} = error -> error
    end
  end

  defp verify_compatibility(%ArtifactPin{} = pin, opts) do
    case Keyword.get(opts, :compatibility) do
      nil -> {:ok, nil}
      requirement -> ArtifactPin.validate_compatibility(pin, requirement)
    end
  end

  defp receipt_metadata(nil), do: %{}

  defp receipt_metadata(%ProviderCompatibility{} = compatibility),
    do: %{compatibility: ProviderCompatibility.to_map(compatibility)}

  defp now(opts) do
    opts
    |> Keyword.get(:now, &DateTime.utc_now/0)
    |> then(& &1.())
  end
end
