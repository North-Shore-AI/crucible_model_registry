defmodule CrucibleModelRegistry.Stages.Promote do
  @moduledoc "Crucible stage for promoting model versions."

  if Code.ensure_loaded?(Crucible.Stage) do
    @behaviour Crucible.Stage
  end

  @impl true
  def describe(_opts) do
    %{
      name: :model_promote,
      description: "Promotes a model version to a lifecycle stage (staging, production, etc.)",
      required: [:stage],
      optional: [:version],
      types: %{
        stage: {:enum, [:development, :staging, :production, :archived]},
        version: :map
      }
    }
  end

  @doc "Run the promote stage."
  @impl true
  @spec run(term(), map()) :: {:ok, term()} | {:error, term()}
  def run(context, opts) when is_map(opts) do
    stage = Map.fetch!(opts, :stage)
    version = Map.get(opts, :version) || get_artifact(context, :model_version)

    case CrucibleModelRegistry.promote(version, stage) do
      {:ok, updated} -> {:ok, put_artifact(context, :model_version, updated)}
      {:error, _} = error -> error
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
end
