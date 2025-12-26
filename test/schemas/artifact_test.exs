defmodule CrucibleModelRegistry.Schemas.ArtifactTest do
  use CrucibleModelRegistry.DataCase, async: true

  alias CrucibleModelRegistry.Schemas.Artifact

  test "changeset requires core fields" do
    changeset = Artifact.changeset(%Artifact{}, %{})

    assert %{
             model_version_id: ["can't be blank"],
             type: ["can't be blank"],
             storage_backend: ["can't be blank"],
             storage_path: ["can't be blank"]
           } = errors_on(changeset)
  end
end
