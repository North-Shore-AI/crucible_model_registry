defmodule CrucibleModelRegistry.Storage.HuggingFace.Client do
  @moduledoc "Default HuggingFace client adapter (placeholder)."

  @behaviour CrucibleModelRegistry.Storage.HuggingFaceClient

  @doc false
  @impl true
  def upload(_local_path, _remote_path, _opts), do: {:error, :not_configured}

  @doc false
  @impl true
  def download(_remote_path, _local_path, _opts), do: {:error, :not_configured}

  @doc false
  @impl true
  def delete(_remote_path, _opts), do: {:error, :not_configured}

  @doc false
  @impl true
  def exists?(_remote_path, _opts), do: false

  @doc false
  @impl true
  def presigned_url(_remote_path, _expires_in_seconds, _opts), do: {:error, :not_configured}
end
