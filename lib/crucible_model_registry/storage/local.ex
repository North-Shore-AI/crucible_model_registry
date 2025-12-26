defmodule CrucibleModelRegistry.Storage.Local do
  @moduledoc "Local filesystem storage backend."

  @behaviour CrucibleModelRegistry.Storage

  alias CrucibleModelRegistry.Storage.Utils

  @doc false
  @impl true
  def upload(local_path, remote_path, opts) do
    base_path = Keyword.fetch!(opts, :base_path)
    destination = resolve_path(base_path, remote_path)

    Utils.ensure_parent_dir(destination)
    File.cp!(local_path, destination)

    {:ok, %{checksum: Utils.checksum(destination), size_bytes: Utils.size_bytes(destination)}}
  end

  @doc false
  @impl true
  def download(remote_path, local_path, opts) do
    base_path = Keyword.fetch!(opts, :base_path)
    source = resolve_path(base_path, remote_path)

    Utils.ensure_parent_dir(local_path)
    File.cp!(source, local_path)
    :ok
  end

  @doc false
  @impl true
  def delete(remote_path, opts) do
    base_path = Keyword.fetch!(opts, :base_path)
    path = resolve_path(base_path, remote_path)
    File.rm(path)
    :ok
  end

  @doc false
  @impl true
  def exists?(remote_path, opts) do
    base_path = Keyword.fetch!(opts, :base_path)
    path = resolve_path(base_path, remote_path)
    File.exists?(path)
  end

  @doc false
  @impl true
  def presigned_url(remote_path, _expires_in_seconds, opts) do
    base_path = Keyword.fetch!(opts, :base_path)
    path = resolve_path(base_path, remote_path)
    {:ok, path}
  end

  defp resolve_path(base_path, remote_path) do
    base_path = Path.expand(base_path)
    base_prefix = Path.join(base_path, "")
    resolved = Path.expand(Path.join(base_path, remote_path))

    if resolved == base_path or String.starts_with?(resolved, base_prefix) do
      resolved
    else
      raise ArgumentError, "Remote path escapes base_path"
    end
  end
end
