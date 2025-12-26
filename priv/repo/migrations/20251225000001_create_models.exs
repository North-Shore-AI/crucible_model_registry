defmodule CrucibleModelRegistry.Repo.Migrations.CreateModels do
  use Ecto.Migration

  def change do
    create table(:models) do
      add :name, :string, null: false
      add :description, :text
      add :tags, {:array, :string}, default: []
      add :metadata, :map, default: %{}

      timestamps(type: :utc_datetime)
    end

    create unique_index(:models, [:name])
    create index(:models, [:tags])
  end
end
