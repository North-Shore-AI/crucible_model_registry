defmodule CrucibleModelRegistry.Storage.S3 do
  @moduledoc "S3-compatible storage backend."

  @behaviour CrucibleModelRegistry.Storage

  alias CrucibleModelRegistry.Storage.Utils

  @doc false
  @impl true
  def upload(local_path, remote_path, opts) do
    {bucket, key} = parse_remote(remote_path, opts)
    client = Keyword.get(opts, :client, CrucibleModelRegistry.Storage.S3.Client)

    with {:ok, body} <- File.read(local_path),
         {:ok, _} <- client.put_object(bucket, key, body, opts) do
      {:ok, %{checksum: Utils.checksum(local_path), size_bytes: Utils.size_bytes(local_path)}}
    end
  end

  @doc false
  @impl true
  def download(remote_path, local_path, opts) do
    {bucket, key} = parse_remote(remote_path, opts)
    client = Keyword.get(opts, :client, CrucibleModelRegistry.Storage.S3.Client)

    with {:ok, %{body: body}} <- client.get_object(bucket, key, opts) do
      Utils.ensure_parent_dir(local_path)
      File.write!(local_path, body)
      :ok
    end
  end

  @doc false
  @impl true
  def delete(remote_path, opts) do
    {bucket, key} = parse_remote(remote_path, opts)
    client = Keyword.get(opts, :client, CrucibleModelRegistry.Storage.S3.Client)

    client.delete_object(bucket, key, opts)
  end

  @doc false
  @impl true
  def exists?(remote_path, opts) do
    {bucket, key} = parse_remote(remote_path, opts)
    client = Keyword.get(opts, :client, CrucibleModelRegistry.Storage.S3.Client)

    case client.head_object(bucket, key, opts) do
      {:ok, _} -> true
      {:error, :not_found} -> false
      {:error, _} -> false
    end
  end

  @doc false
  @impl true
  def presigned_url(remote_path, expires_in_seconds, opts) do
    {bucket, key} = parse_remote(remote_path, opts)
    client = Keyword.get(opts, :client, CrucibleModelRegistry.Storage.S3.Client)

    client.presigned_url(bucket, key, expires_in_seconds, opts)
  end

  defp parse_remote(remote_path, opts) do
    uri = URI.parse(remote_path)

    if uri.scheme == "s3" do
      {uri.host, String.trim_leading(uri.path || "", "/")}
    else
      bucket = Keyword.fetch!(opts, :bucket)
      {bucket, remote_path}
    end
  end
end
