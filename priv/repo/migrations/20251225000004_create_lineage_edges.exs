defmodule CrucibleModelRegistry.Repo.Migrations.CreateLineageEdges do
  use Ecto.Migration

  def change do
    create table(:lineage_edges) do
      add :source_version_id, references(:model_versions, on_delete: :delete_all), null: false
      add :target_version_id, references(:model_versions, on_delete: :delete_all), null: false
      add :relationship, :string, null: false
      add :metadata, :map, default: %{}

      timestamps(type: :utc_datetime)
    end

    create unique_index(:lineage_edges, [:source_version_id, :target_version_id, :relationship],
             name: :lineage_edges_source_version_id_target_version_id_relationship_index
           )

    create index(:lineage_edges, [:source_version_id])
    create index(:lineage_edges, [:target_version_id])
  end
end
