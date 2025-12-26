defmodule CrucibleModelRegistry.Storage.HuggingFaceClient do
  @moduledoc "Behaviour for HuggingFace Hub client adapters."

  @callback upload(Path.t(), String.t(), keyword()) ::
              {:ok, %{checksum: String.t(), size_bytes: integer()}} | {:error, term()}
  @callback download(String.t(), Path.t(), keyword()) :: :ok | {:error, term()}
  @callback delete(String.t(), keyword()) :: :ok | {:error, term()}
  @callback exists?(String.t(), keyword()) :: boolean()
  @callback presigned_url(String.t(), integer(), keyword()) ::
              {:ok, String.t()} | {:error, term()}
end
