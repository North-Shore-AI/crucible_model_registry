defmodule CrucibleModelRegistry.Schemas.LineageEdge do
  @moduledoc "Schema for lineage relationships between model versions."

  use Ecto.Schema
  import Ecto.Changeset

  @type relationship :: :fine_tuned_from | :distilled_from | :rl_trained_from | :dpo_trained_from

  @type t :: %__MODULE__{
          id: integer() | nil,
          source_version_id: integer() | nil,
          target_version_id: integer() | nil,
          source_version:
            CrucibleModelRegistry.Schemas.ModelVersion.t()
            | Ecto.Association.NotLoaded.t()
            | nil,
          target_version:
            CrucibleModelRegistry.Schemas.ModelVersion.t()
            | Ecto.Association.NotLoaded.t()
            | nil,
          relationship: relationship() | nil,
          metadata: map(),
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  schema "lineage_edges" do
    belongs_to :source_version, CrucibleModelRegistry.Schemas.ModelVersion
    belongs_to :target_version, CrucibleModelRegistry.Schemas.ModelVersion

    field :relationship, Ecto.Enum,
      values: [:fine_tuned_from, :distilled_from, :rl_trained_from, :dpo_trained_from]

    field :metadata, :map, default: %{}

    timestamps(type: :utc_datetime)
  end

  @doc "Builds a changeset for lineage edges."
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(edge, attrs) do
    edge
    |> cast(attrs, [:source_version_id, :target_version_id, :relationship, :metadata])
    |> validate_required([:source_version_id, :target_version_id, :relationship])
    |> unique_constraint(:relationship,
      name: :lineage_edges_source_version_id_target_version_id_relationship_index
    )
  end
end
