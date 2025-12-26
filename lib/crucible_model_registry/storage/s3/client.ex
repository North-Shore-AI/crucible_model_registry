defmodule CrucibleModelRegistry.Storage.S3.Client do
  @moduledoc "Default S3 client adapter using ExAws."

  @behaviour CrucibleModelRegistry.Storage.S3Client

  @doc false
  @impl true
  def put_object(bucket, key, body, opts) do
    ExAws.S3.put_object(bucket, key, body)
    |> ExAws.request(aws_config(opts))
  end

  @doc false
  @impl true
  def get_object(bucket, key, opts) do
    ExAws.S3.get_object(bucket, key)
    |> ExAws.request(aws_config(opts))
  end

  @doc false
  @impl true
  def delete_object(bucket, key, opts) do
    ExAws.S3.delete_object(bucket, key)
    |> ExAws.request(aws_config(opts))
    |> case do
      {:ok, _} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  @doc false
  @impl true
  def head_object(bucket, key, opts) do
    ExAws.S3.head_object(bucket, key)
    |> ExAws.request(aws_config(opts))
  end

  @doc false
  @impl true
  def presigned_url(bucket, key, expires_in, opts) do
    case ExAws.S3.presigned_url(aws_config(opts), :get, bucket, key, expires_in: expires_in) do
      {:ok, url} -> {:ok, url}
      {:error, reason} -> {:error, reason}
    end
  end

  defp aws_config(opts) do
    Keyword.get(opts, :ex_aws_config) || ExAws.Config.new(:s3, opts)
  end
end
