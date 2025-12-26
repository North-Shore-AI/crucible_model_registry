defmodule CrucibleModelRegistry.Schemas.Model do
  @moduledoc "Schema for logical model groupings."

  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: integer() | nil,
          name: String.t() | nil,
          description: String.t() | nil,
          tags: [String.t()],
          metadata: map(),
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  schema "models" do
    field :name, :string
    field :description, :string
    field :tags, {:array, :string}, default: []
    field :metadata, :map, default: %{}

    has_many :versions, CrucibleModelRegistry.Schemas.ModelVersion

    timestamps(type: :utc_datetime)
  end

  @doc "Builds a changeset for models."
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(model, attrs) do
    model
    |> cast(attrs, [:name, :description, :tags, :metadata])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end
end
