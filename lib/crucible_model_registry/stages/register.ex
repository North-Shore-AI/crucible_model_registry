defmodule CrucibleModelRegistry.Stages.Register do
  @moduledoc "Crucible stage for registering trained models."

  if Code.ensure_loaded?(Crucible.Stage) do
    @behaviour Crucible.Stage
  end

  @doc "Run the registration stage."
  @spec run(term(), map()) :: {:ok, term()} | {:error, term()}
  def run(context, opts) when is_map(opts) do
    artifacts = resolve_artifacts(context, opts)
    training_config = resolve_training_config(context, opts)
    metrics = resolve_metrics(context)

    params = %{
      model_name: Map.fetch!(opts, :model_name),
      version: Map.get(opts, :version) || generate_version(),
      recipe: Map.fetch!(opts, :recipe),
      base_model: Map.fetch!(opts, :base_model),
      training_config: training_config,
      metrics: metrics,
      artifacts: artifacts,
      parent_version_id: Map.get(opts, :parent_version_id),
      lineage_type: Map.get(opts, :lineage_type)
    }

    case CrucibleModelRegistry.register(params) do
      {:ok, version} ->
        {:ok, put_artifact(context, :model_version, version)}

      {:error, _} = error ->
        error
    end
  end

  defp resolve_training_config(context, opts) do
    Map.get(opts, :training_config) ||
      get_artifact(context, :training_config) ||
      %{}
  end

  defp resolve_metrics(context) do
    case context do
      %Crucible.Context{metrics: metrics} -> metrics
      %{metrics: metrics} when is_map(metrics) -> metrics
      _ -> %{}
    end
  end

  defp resolve_artifacts(context, opts) do
    cond do
      Map.get(opts, :artifacts) ->
        Map.get(opts, :artifacts)

      checkpoint_id = get_artifact(context, :checkpoint_id) ->
        [%{type: :checkpoint, storage_backend: :tinker, storage_path: checkpoint_id}]

      true ->
        []
    end
  end

  defp get_artifact(context, key) do
    if Code.ensure_loaded?(Crucible.Context) and match?(%Crucible.Context{}, context) do
      Crucible.Context.get_artifact(context, key, nil)
    else
      Map.get(context, key)
    end
  end

  defp put_artifact(context, key, value) do
    if Code.ensure_loaded?(Crucible.Context) and match?(%Crucible.Context{}, context) do
      Crucible.Context.put_artifact(context, key, value)
    else
      Map.put(context, key, value)
    end
  end

  defp generate_version do
    DateTime.utc_now() |> DateTime.to_iso8601()
  end
end
