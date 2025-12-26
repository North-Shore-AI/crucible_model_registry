defmodule CrucibleModelRegistry.Storage do
  @moduledoc "Behaviour and helpers for artifact storage backends."

  @type upload_opts :: keyword()

  @callback upload(local_path :: Path.t(), remote_path :: String.t(), opts :: upload_opts()) ::
              {:ok, %{checksum: String.t(), size_bytes: integer()}} | {:error, term()}

  @callback download(remote_path :: String.t(), local_path :: Path.t(), opts :: upload_opts()) ::
              :ok | {:error, term()}

  @callback delete(remote_path :: String.t(), opts :: upload_opts()) :: :ok | {:error, term()}

  @callback exists?(remote_path :: String.t(), opts :: upload_opts()) :: boolean()

  @callback presigned_url(
              remote_path :: String.t(),
              expires_in_seconds :: integer(),
              opts :: upload_opts()
            ) ::
              {:ok, String.t()} | {:error, term()}

  @backend_map %{
    s3: CrucibleModelRegistry.Storage.S3,
    huggingface: CrucibleModelRegistry.Storage.HuggingFace,
    local: CrucibleModelRegistry.Storage.Local,
    noop: CrucibleModelRegistry.Storage.Noop
  }

  @doc "Returns the configured storage backend module."
  @spec backend() :: module()
  def backend do
    value = Application.get_env(:crucible_model_registry, :storage_backend, :noop)

    cond do
      is_atom(value) and Map.has_key?(@backend_map, value) ->
        Map.fetch!(@backend_map, value)

      is_atom(value) ->
        value

      true ->
        raise ArgumentError, "Invalid storage backend: #{inspect(value)}"
    end
  end

  @doc "Returns default storage options."
  @spec opts() :: keyword()
  def opts do
    Application.get_env(:crucible_model_registry, :storage_opts, [])
  end

  @doc "Uploads an artifact using the configured backend."
  @spec upload(Path.t(), String.t(), upload_opts()) ::
          {:ok, %{checksum: String.t(), size_bytes: integer()}} | {:error, term()}
  def upload(local_path, remote_path, extra_opts \\ []) do
    backend().upload(local_path, remote_path, Keyword.merge(opts(), extra_opts))
  end

  @doc "Downloads an artifact using the configured backend."
  @spec download(String.t(), Path.t(), upload_opts()) :: :ok | {:error, term()}
  def download(remote_path, local_path, extra_opts \\ []) do
    backend().download(remote_path, local_path, Keyword.merge(opts(), extra_opts))
  end

  @doc "Deletes an artifact using the configured backend."
  @spec delete(String.t(), upload_opts()) :: :ok | {:error, term()}
  def delete(remote_path, extra_opts \\ []) do
    backend().delete(remote_path, Keyword.merge(opts(), extra_opts))
  end

  @doc "Checks whether an artifact exists in storage."
  @spec exists?(String.t(), upload_opts()) :: boolean()
  def exists?(remote_path, extra_opts \\ []) do
    backend().exists?(remote_path, Keyword.merge(opts(), extra_opts))
  end

  @doc "Returns a presigned download URL for an artifact."
  @spec presigned_url(String.t(), integer(), upload_opts()) ::
          {:ok, String.t()} | {:error, term()}
  def presigned_url(remote_path, expires_in_seconds, extra_opts \\ []) do
    backend().presigned_url(remote_path, expires_in_seconds, Keyword.merge(opts(), extra_opts))
  end
end
