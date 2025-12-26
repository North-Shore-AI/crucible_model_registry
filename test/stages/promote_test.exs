if Code.ensure_loaded?(Crucible.Context) and Code.ensure_loaded?(CrucibleIR.Experiment) do
  defmodule CrucibleModelRegistry.Stages.PromoteTest do
    use CrucibleModelRegistry.DataCase, async: true

    alias Crucible.Context
    alias CrucibleModelRegistry.Stages.Promote

    test "promote stage updates model_version artifact" do
      experiment = %CrucibleIR.Experiment{
        id: :test,
        backend: %CrucibleIR.BackendRef{id: :mock},
        pipeline: []
      }

      context = %Context{experiment_id: "exp1", run_id: "run1", experiment: experiment}
      version = insert(:model_version, stage: :staging)
      context = Context.put_artifact(context, :model_version, version)

      {:ok, updated} = Promote.run(context, %{stage: :production})

      assert %CrucibleModelRegistry.Schemas.ModelVersion{stage: :production} =
               Context.get_artifact(updated, :model_version)
    end
  end
end
