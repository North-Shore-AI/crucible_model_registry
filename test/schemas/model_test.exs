defmodule CrucibleModelRegistry.Schemas.ModelTest do
  use CrucibleModelRegistry.DataCase, async: true

  alias CrucibleModelRegistry.Schemas.Model

  test "changeset requires name" do
    changeset = Model.changeset(%Model{}, %{})
    assert %{name: ["can't be blank"]} = errors_on(changeset)
  end

  test "changeset accepts tags and metadata" do
    changeset =
      Model.changeset(%Model{}, %{name: "llama-3", tags: ["prod"], metadata: %{foo: "bar"}})

    assert changeset.valid?
    assert changeset.changes.tags == ["prod"]
    assert changeset.changes.metadata == %{foo: "bar"}
  end

  test "name must be unique" do
    insert(:model, name: "unique-model")

    {:error, changeset} =
      %Model{}
      |> Model.changeset(%{name: "unique-model"})
      |> Repo.insert()

    assert %{name: ["has already been taken"]} = errors_on(changeset)
  end
end
