defmodule CrucibleModelRegistry.Storage.Noop do
  @moduledoc "No-op storage backend for testing and development."

  @behaviour CrucibleModelRegistry.Storage

  @doc false
  @impl true
  def upload(_local_path, _remote_path, _opts),
    do: {:ok, %{checksum: "noop", size_bytes: 0}}

  @doc false
  @impl true
  def download(_remote_path, _local_path, _opts), do: :ok

  @doc false
  @impl true
  def delete(_remote_path, _opts), do: :ok

  @doc false
  @impl true
  def exists?(_remote_path, _opts), do: false

  @doc false
  @impl true
  def presigned_url(_remote_path, _expires_in_seconds, _opts), do: {:error, :not_supported}
end
