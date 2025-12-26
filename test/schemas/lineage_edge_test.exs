defmodule CrucibleModelRegistry.Schemas.LineageEdgeTest do
  use CrucibleModelRegistry.DataCase, async: true

  alias CrucibleModelRegistry.Schemas.LineageEdge

  test "changeset requires core fields" do
    changeset = LineageEdge.changeset(%LineageEdge{}, %{})

    assert %{
             source_version_id: ["can't be blank"],
             target_version_id: ["can't be blank"],
             relationship: ["can't be blank"]
           } = errors_on(changeset)
  end
end
