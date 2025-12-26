defmodule CrucibleModelRegistry.Storage.HuggingFace do
  @moduledoc "HuggingFace Hub storage backend."

  @behaviour CrucibleModelRegistry.Storage

  @doc false
  @impl true
  def upload(local_path, remote_path, opts) do
    client = Keyword.get(opts, :client, CrucibleModelRegistry.Storage.HuggingFace.Client)
    client.upload(local_path, remote_path, opts)
  end

  @doc false
  @impl true
  def download(remote_path, local_path, opts) do
    client = Keyword.get(opts, :client, CrucibleModelRegistry.Storage.HuggingFace.Client)
    client.download(remote_path, local_path, opts)
  end

  @doc false
  @impl true
  def delete(remote_path, opts) do
    client = Keyword.get(opts, :client, CrucibleModelRegistry.Storage.HuggingFace.Client)
    client.delete(remote_path, opts)
  end

  @doc false
  @impl true
  def exists?(remote_path, opts) do
    client = Keyword.get(opts, :client, CrucibleModelRegistry.Storage.HuggingFace.Client)
    client.exists?(remote_path, opts)
  end

  @doc false
  @impl true
  def presigned_url(remote_path, expires_in_seconds, opts) do
    client = Keyword.get(opts, :client, CrucibleModelRegistry.Storage.HuggingFace.Client)
    client.presigned_url(remote_path, expires_in_seconds, opts)
  end
end
