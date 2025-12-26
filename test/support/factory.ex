defmodule CrucibleModelRegistry.Factory do
  @moduledoc "Factories for registry tests."

  use ExMachina.Ecto, repo: CrucibleModelRegistry.Repo

  def model_factory do
    %CrucibleModelRegistry.Schemas.Model{
      name: sequence(:name, &"model-#{&1}"),
      tags: ["test"],
      metadata: %{}
    }
  end

  def model_version_factory do
    %CrucibleModelRegistry.Schemas.ModelVersion{
      model: build(:model),
      version: sequence(:version, &"1.0.#{&1}"),
      stage: :experiment,
      recipe: "sl_basic",
      base_model: "meta-llama/Llama-3.1-8B",
      training_config: %{"lr" => 1.0e-4},
      config_hash: "config-hash"
    }
  end

  def artifact_factory do
    %CrucibleModelRegistry.Schemas.Artifact{
      model_version: build(:model_version),
      type: :checkpoint,
      storage_backend: :local,
      storage_path: "artifacts/model.ckpt",
      checksum: "checksum",
      size_bytes: 1024
    }
  end

  def lineage_edge_factory do
    %CrucibleModelRegistry.Schemas.LineageEdge{
      source_version: build(:model_version),
      target_version: build(:model_version),
      relationship: :fine_tuned_from,
      metadata: %{}
    }
  end
end
