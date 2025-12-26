defmodule CrucibleModelRegistry.Schemas.Artifact do
  @moduledoc "Schema for physical artifact storage references."

  use Ecto.Schema
  import Ecto.Changeset

  @type artifact_type :: :checkpoint | :config | :tokenizer | :merged | :gguf | :onnx | :tensorrt
  @type storage_backend :: :s3 | :huggingface | :local | :tinker

  @type t :: %__MODULE__{
          id: integer() | nil,
          model_version_id: integer() | nil,
          model_version:
            CrucibleModelRegistry.Schemas.ModelVersion.t()
            | Ecto.Association.NotLoaded.t()
            | nil,
          type: artifact_type() | nil,
          storage_backend: storage_backend() | nil,
          storage_path: String.t() | nil,
          checksum: String.t() | nil,
          size_bytes: integer() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  schema "artifacts" do
    belongs_to :model_version, CrucibleModelRegistry.Schemas.ModelVersion

    field :type, Ecto.Enum,
      values: [:checkpoint, :config, :tokenizer, :merged, :gguf, :onnx, :tensorrt]

    field :storage_backend, Ecto.Enum, values: [:s3, :huggingface, :local, :tinker]
    field :storage_path, :string
    field :checksum, :string
    field :size_bytes, :integer

    timestamps(type: :utc_datetime)
  end

  @doc "Builds a changeset for artifacts."
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(artifact, attrs) do
    artifact
    |> cast(attrs, [
      :model_version_id,
      :type,
      :storage_backend,
      :storage_path,
      :checksum,
      :size_bytes
    ])
    |> validate_required([:model_version_id, :type, :storage_backend, :storage_path])
  end
end
