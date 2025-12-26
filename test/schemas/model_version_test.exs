defmodule CrucibleModelRegistry.Schemas.ModelVersionTest do
  use CrucibleModelRegistry.DataCase, async: true

  alias CrucibleModelRegistry.Schemas.ModelVersion

  test "changeset requires core fields" do
    changeset = ModelVersion.changeset(%ModelVersion{}, %{})

    assert %{
             model_id: ["can't be blank"],
             version: ["can't be blank"],
             recipe: ["can't be blank"],
             base_model: ["can't be blank"],
             config_hash: ["can't be blank"]
           } = errors_on(changeset)
  end

  test "changeset enforces unique model_id+version" do
    model = insert(:model)
    insert(:model_version, model: model, version: "1.0.0", config_hash: "hash-1")

    {:error, changeset} =
      %ModelVersion{}
      |> ModelVersion.changeset(%{
        model_id: model.id,
        version: "1.0.0",
        stage: :experiment,
        recipe: "sl_basic",
        base_model: "meta-llama/Llama-3.1-8B",
        config_hash: "hash-2",
        training_config: %{"lr" => 1.0e-4}
      })
      |> Repo.insert()

    assert %{version: ["has already been taken"]} = errors_on(changeset)
  end
end
