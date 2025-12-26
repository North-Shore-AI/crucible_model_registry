defmodule CrucibleModelRegistry.Schemas.ModelVersion do
  @moduledoc "Schema for specific trained model versions."

  use Ecto.Schema
  import Ecto.Changeset

  @type stage :: :experiment | :staging | :production | :archived
  @type lineage_type :: :fine_tuned_from | :distilled_from | :rl_trained_from | :dpo_trained_from

  @type t :: %__MODULE__{
          id: integer() | nil,
          model_id: integer() | nil,
          model: CrucibleModelRegistry.Schemas.Model.t() | Ecto.Association.NotLoaded.t() | nil,
          version: String.t() | nil,
          stage: stage(),
          recipe: String.t() | nil,
          base_model: String.t() | nil,
          config_hash: String.t() | nil,
          training_config: map(),
          metrics: map(),
          parent_version_id: integer() | nil,
          lineage_type: lineage_type() | nil,
          artifacts:
            [CrucibleModelRegistry.Schemas.Artifact.t()] | Ecto.Association.NotLoaded.t(),
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  schema "model_versions" do
    belongs_to :model, CrucibleModelRegistry.Schemas.Model

    field :version, :string

    field :stage, Ecto.Enum,
      values: [:experiment, :staging, :production, :archived],
      default: :experiment

    field :recipe, :string
    field :base_model, :string
    field :config_hash, :string
    field :training_config, :map, default: %{}

    field :metrics, :map, default: %{}

    field :parent_version_id, :id

    field :lineage_type, Ecto.Enum,
      values: [:fine_tuned_from, :distilled_from, :rl_trained_from, :dpo_trained_from]

    has_many :artifacts, CrucibleModelRegistry.Schemas.Artifact

    timestamps(type: :utc_datetime)
  end

  @doc "Builds a changeset for model versions."
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(version, attrs) do
    version
    |> cast(attrs, [
      :model_id,
      :version,
      :stage,
      :recipe,
      :base_model,
      :config_hash,
      :training_config,
      :metrics,
      :parent_version_id,
      :lineage_type
    ])
    |> validate_required([
      :model_id,
      :version,
      :recipe,
      :base_model,
      :config_hash,
      :training_config
    ])
    |> unique_constraint(:version, name: :model_versions_model_id_version_index)
  end
end
