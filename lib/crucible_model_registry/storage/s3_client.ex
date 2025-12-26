defmodule CrucibleModelRegistry.Storage.S3Client do
  @moduledoc "Behaviour for S3 client adapters."

  @callback put_object(String.t(), String.t(), binary(), keyword()) ::
              {:ok, term()} | {:error, term()}
  @callback get_object(String.t(), String.t(), keyword()) ::
              {:ok, %{body: binary()}} | {:error, term()}
  @callback delete_object(String.t(), String.t(), keyword()) :: :ok | {:error, term()}
  @callback head_object(String.t(), String.t(), keyword()) :: {:ok, term()} | {:error, term()}
  @callback presigned_url(String.t(), String.t(), integer(), keyword()) ::
              {:ok, String.t()} | {:error, term()}
end
