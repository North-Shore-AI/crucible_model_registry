defmodule CrucibleModelRegistry.Repo.Migrations.CreateModelVersions do
  use Ecto.Migration

  def change do
    create table(:model_versions) do
      add :model_id, references(:models, on_delete: :delete_all), null: false
      add :version, :string, null: false
      add :stage, :string, null: false, default: "experiment"

      add :recipe, :string, null: false
      add :base_model, :string, null: false
      add :config_hash, :string, null: false
      add :training_config, :map, null: false
      add :metrics, :map, default: %{}

      add :parent_version_id, references(:model_versions, on_delete: :nilify_all)
      add :lineage_type, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:model_versions, [:model_id, :version],
             name: :model_versions_model_id_version_index
           )

    create index(:model_versions, [:config_hash])
    create index(:model_versions, [:stage])
    create index(:model_versions, [:recipe])
    create index(:model_versions, [:base_model])
    create index(:model_versions, [:parent_version_id])
  end
end
