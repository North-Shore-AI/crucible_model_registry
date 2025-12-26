defmodule CrucibleModelRegistry.Repo.Migrations.CreateArtifacts do
  use Ecto.Migration

  def change do
    create table(:artifacts) do
      add :model_version_id, references(:model_versions, on_delete: :delete_all), null: false
      add :type, :string, null: false
      add :storage_backend, :string, null: false
      add :storage_path, :string, null: false
      add :checksum, :string
      add :size_bytes, :bigint

      timestamps(type: :utc_datetime)
    end

    create index(:artifacts, [:model_version_id])
    create index(:artifacts, [:type])
    create unique_index(:artifacts, [:storage_path])
  end
end
