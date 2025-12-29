defmodule CrucibleModelRegistry do
  @moduledoc """
  Model registry for ML artifacts with lineage tracking.

  ## Database Configuration

  CrucibleModelRegistry requires a Repo for persistence. Configure it in your host application:

      config :crucible_model_registry, repo: MyApp.Repo

  Then start your Repo in your supervision tree. Run migrations:

      mix crucible_model_registry.install

  Or copy migrations from `deps/crucible_model_registry/priv/repo/migrations/`.
  """

  alias CrucibleModelRegistry.{ConfigHash, Lineage, Query, Storage}
  alias CrucibleModelRegistry.Schemas.{Artifact, Model, ModelVersion}

  @doc """
  Returns the configured Repo module.

  Raises if not configured. Configure with:

      config :crucible_model_registry, repo: MyApp.Repo
  """
  @spec repo() :: module()
  def repo do
    Application.get_env(:crucible_model_registry, :repo) ||
      raise ArgumentError, """
      CrucibleModelRegistry requires a :repo configuration.

      Add to your config:

          config :crucible_model_registry, repo: MyApp.Repo
      """
  end

  @type stage :: ModelVersion.stage()
  @type artifact_type :: Artifact.artifact_type()

  @doc "Register a new model version, inserting model, version, artifacts, and lineage."
  @spec register(map()) :: {:ok, ModelVersion.t()} | {:error, term()}
  def register(params) when is_map(params) do
    with {:ok, attrs} <- normalize_register_params(params),
         :ok <- ensure_unique_config(attrs.config_hash) do
      result =
        repo().transaction(fn ->
          model = get_or_create_model!(attrs.model_name, Map.get(attrs, :model_meta, %{}))

          {:ok, version} =
            %ModelVersion{}
            |> ModelVersion.changeset(%{
              model_id: model.id,
              version: attrs.version,
              stage: attrs.stage,
              recipe: attrs.recipe,
              base_model: attrs.base_model,
              config_hash: attrs.config_hash,
              training_config: attrs.training_config,
              metrics: attrs.metrics,
              parent_version_id: attrs.parent_version_id,
              lineage_type: attrs.lineage_type
            })
            |> repo().insert()

          artifacts = insert_artifacts!(version, attrs.artifacts)

          case maybe_insert_lineage_edge!(version, attrs.parent_version_id, attrs.lineage_type) do
            :ok -> :ok
            {:ok, _edge} -> :ok
            {:error, reason} -> repo().rollback(reason)
          end

          version = %{version | artifacts: artifacts, model: model}
          emit([:register], %{count: 1}, %{model_name: model.name, version: version.version})

          version
        end)

      case result do
        {:ok, version} -> {:ok, version}
        {:error, reason} -> {:error, reason}
      end
    end
  end

  @doc "Query model versions using filter maps."
  @spec query(map()) :: [ModelVersion.t()]
  def query(filters) when is_map(filters) do
    filters
    |> Query.from_filters()
    |> Query.execute()
  end

  @doc "Get a model by name."
  @spec get_model(String.t()) :: {:ok, Model.t()} | {:error, :not_found}
  def get_model(name) do
    case repo().get_by(Model, name: name) do
      nil -> {:error, :not_found}
      model -> {:ok, model}
    end
  end

  @doc "Get a model version by id."
  @spec get_version(integer()) :: {:ok, ModelVersion.t()} | {:error, :not_found}
  def get_version(id) do
    case repo().get(ModelVersion, id) do
      nil -> {:error, :not_found}
      version -> {:ok, version}
    end
  end

  @doc "Return all ancestors for a model version."
  @spec get_ancestors(ModelVersion.t()) :: [ModelVersion.t()]
  def get_ancestors(%ModelVersion{} = version) do
    Lineage.ancestors(version)
  end

  @doc "Return all descendants for a model version."
  @spec get_descendants(ModelVersion.t()) :: [ModelVersion.t()]
  def get_descendants(%ModelVersion{} = version) do
    Lineage.descendants(version)
  end

  @doc "Find a version by config hash."
  @spec find_by_config_hash(String.t()) :: {:ok, ModelVersion.t()} | :not_found
  def find_by_config_hash(hash) when is_binary(hash) do
    case repo().get_by(ModelVersion, config_hash: hash) do
      nil -> :not_found
      version -> {:ok, version}
    end
  end

  @doc "Promote a version to a new stage."
  @spec promote(ModelVersion.t(), stage()) :: {:ok, ModelVersion.t()} | {:error, term()}
  def promote(%ModelVersion{} = version, new_stage) do
    version
    |> ModelVersion.changeset(%{stage: new_stage})
    |> repo().update()
    |> case do
      {:ok, updated} ->
        emit([:promote], %{count: 1}, %{id: updated.id, stage: updated.stage})
        {:ok, updated}

      {:error, _} = error ->
        error
    end
  end

  @doc "Upload an artifact and register it in the registry."
  @spec upload_artifact(ModelVersion.t(), artifact_type(), Path.t()) ::
          {:ok, Artifact.t()} | {:error, term()}
  def upload_artifact(%ModelVersion{} = version, type, local_path) do
    version = repo().preload(version, :model)
    remote_path = artifact_remote_path(version.model.name, version.version, type, local_path)

    case Storage.upload(local_path, remote_path, []) do
      {:ok, %{checksum: checksum, size_bytes: size_bytes}} ->
        attrs = %{
          model_version_id: version.id,
          type: type,
          storage_backend: storage_backend_atom(Storage.backend()),
          storage_path: remote_path,
          checksum: checksum,
          size_bytes: size_bytes
        }

        %Artifact{}
        |> Artifact.changeset(attrs)
        |> repo().insert()
        |> case do
          {:ok, artifact} ->
            emit([:upload], %{size_bytes: size_bytes}, %{model_version_id: version.id})
            {:ok, artifact}

          {:error, reason} ->
            {:error, reason}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc "Download an artifact to a local path."
  @spec download_artifact(Artifact.t(), Path.t()) :: :ok | {:error, term()}
  def download_artifact(%Artifact{} = artifact, local_path) do
    backend = storage_module_for(artifact.storage_backend)

    case backend.download(artifact.storage_path, local_path, Storage.opts()) do
      :ok ->
        emit([:download], %{count: 1}, %{artifact_id: artifact.id})
        :ok

      {:error, _} = error ->
        error
    end
  end

  defp normalize_register_params(params) do
    required = [:model_name, :version, :recipe, :base_model, :training_config]
    missing = Enum.filter(required, &is_nil(Map.get(params, &1)))

    if missing != [] do
      {:error, {:missing_params, missing}}
    else
      config_hash = ConfigHash.hash_config(Map.fetch!(params, :training_config))
      parent_version_id = extract_parent_version_id(params)
      stage = Map.get(params, :stage, :experiment)

      {:ok,
       %{
         model_name: Map.fetch!(params, :model_name),
         version: Map.fetch!(params, :version),
         recipe: Map.fetch!(params, :recipe),
         base_model: Map.fetch!(params, :base_model),
         training_config: Map.fetch!(params, :training_config),
         metrics: Map.get(params, :metrics, %{}),
         artifacts: Map.get(params, :artifacts, []),
         config_hash: config_hash,
         parent_version_id: parent_version_id,
         lineage_type: Map.get(params, :lineage_type),
         stage: stage,
         model_meta: Map.get(params, :model_meta, %{})
       }}
    end
  end

  defp extract_parent_version_id(%{parent_version_id: id}) when is_integer(id), do: id
  defp extract_parent_version_id(%{parent_version: %ModelVersion{id: id}}), do: id
  defp extract_parent_version_id(_), do: nil

  defp ensure_unique_config(config_hash) do
    case find_by_config_hash(config_hash) do
      {:ok, version} -> {:error, {:duplicate_config, version}}
      :not_found -> :ok
    end
  end

  defp get_or_create_model!(name, meta) do
    repo().get_by(Model, name: name) ||
      %Model{}
      |> Model.changeset(Map.merge(%{name: name}, meta))
      |> repo().insert!()
  end

  defp insert_artifacts!(_version, []), do: []

  defp insert_artifacts!(version, artifacts) do
    Enum.map(artifacts, fn artifact ->
      artifact_attrs =
        artifact
        |> Map.new()
        |> Map.put(:model_version_id, version.id)

      %Artifact{}
      |> Artifact.changeset(artifact_attrs)
      |> repo().insert!()
    end)
  end

  defp maybe_insert_lineage_edge!(_version, nil, _lineage_type), do: :ok

  defp maybe_insert_lineage_edge!(version, parent_version_id, lineage_type) do
    relationship = lineage_type || :fine_tuned_from

    Lineage.add_edge(%{
      source_version_id: parent_version_id,
      target_version_id: version.id,
      relationship: relationship
    })
  end

  defp storage_backend_atom(CrucibleModelRegistry.Storage.S3), do: :s3
  defp storage_backend_atom(CrucibleModelRegistry.Storage.HuggingFace), do: :huggingface
  defp storage_backend_atom(CrucibleModelRegistry.Storage.Local), do: :local
  defp storage_backend_atom(_), do: :tinker

  defp storage_module_for(:s3), do: CrucibleModelRegistry.Storage.S3
  defp storage_module_for(:huggingface), do: CrucibleModelRegistry.Storage.HuggingFace
  defp storage_module_for(:local), do: CrucibleModelRegistry.Storage.Local
  defp storage_module_for(:tinker), do: Storage.backend()
  defp storage_module_for(_), do: Storage.backend()

  defp artifact_remote_path(model_name, version, type, local_path) do
    filename = Path.basename(local_path)
    Path.join([model_name, version, Atom.to_string(type), filename])
  end

  defp emit(event, measurements, metadata) do
    :telemetry.execute([:crucible_model_registry | event], measurements, metadata)
  end
end
