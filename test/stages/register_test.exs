if Code.ensure_loaded?(Crucible.Context) and Code.ensure_loaded?(CrucibleIR.Experiment) do
  defmodule CrucibleModelRegistry.Stages.RegisterTest do
    use CrucibleModelRegistry.DataCase, async: true

    alias Crucible.Context
    alias CrucibleModelRegistry.Stages.Register

    test "register stage writes model_version artifact" do
      experiment = %CrucibleIR.Experiment{
        id: :test,
        backend: %CrucibleIR.BackendRef{id: :mock},
        pipeline: []
      }

      context = %Context{experiment_id: "exp1", run_id: "run1", experiment: experiment}
      context = Context.put_artifact(context, :checkpoint_id, "ckpt-123")

      {:ok, updated} =
        Register.run(context, %{
          model_name: "stage-model",
          version: "1.0.0",
          recipe: "sl_basic",
          base_model: "meta-llama/Llama-3.1-8B",
          training_config: %{"lr" => 1.0e-4}
        })

      assert %CrucibleModelRegistry.Schemas.ModelVersion{} =
               Context.get_artifact(updated, :model_version)
    end
  end
end
