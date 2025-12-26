defmodule CrucibleModelRegistryTest do
  use CrucibleModelRegistry.DataCase, async: false

  alias CrucibleModelRegistry.{ConfigHash, Repo}
  alias CrucibleModelRegistry.Schemas.ModelVersion

  test "register creates model, version, and artifacts" do
    params = %{
      model_name: "llama-3.1-8b-sft",
      version: "1.0.0",
      recipe: "sl_basic",
      base_model: "meta-llama/Llama-3.1-8B",
      training_config: %{"lr" => 1.0e-4},
      metrics: %{"accuracy" => 0.92},
      artifacts: [
        %{
          type: :checkpoint,
          storage_backend: :local,
          storage_path: "artifacts/llama.bin"
        }
      ]
    }

    assert {:ok, %ModelVersion{} = version} = CrucibleModelRegistry.register(params)
    version = Repo.preload(version, [:model, :artifacts])

    assert version.model.name == "llama-3.1-8b-sft"
    assert version.recipe == "sl_basic"
    assert version.config_hash == ConfigHash.hash_config(%{"lr" => 1.0e-4})
    assert length(version.artifacts) == 1
  end

  test "find_by_config_hash returns matching version" do
    version = insert(:model_version, config_hash: "config-hash-1")

    assert {:ok, found} = CrucibleModelRegistry.find_by_config_hash("config-hash-1")
    assert found.id == version.id
  end

  test "promote updates stage" do
    version = insert(:model_version, stage: :experiment)

    assert {:ok, updated} = CrucibleModelRegistry.promote(version, :staging)
    assert updated.stage == :staging
  end

  test "upload_artifact stores metadata with storage backend" do
    previous = Application.get_env(:crucible_model_registry, :storage_backend)

    Application.put_env(
      :crucible_model_registry,
      :storage_backend,
      CrucibleModelRegistry.Storage.Mock
    )

    on_exit(fn -> Application.put_env(:crucible_model_registry, :storage_backend, previous) end)

    version = insert(:model_version)
    tmp_dir = Path.join(System.tmp_dir!(), "cmr-upload-#{System.unique_integer([:positive])}")
    File.mkdir_p!(tmp_dir)
    local_path = Path.join(tmp_dir, "artifact.bin")
    File.write!(local_path, "artifact-data")

    CrucibleModelRegistry.Storage.Mock
    |> expect(:upload, fn ^local_path, _remote_path, _opts ->
      {:ok, %{checksum: "checksum", size_bytes: 12}}
    end)

    assert {:ok, artifact} =
             CrucibleModelRegistry.upload_artifact(version, :checkpoint, local_path)

    assert artifact.checksum == "checksum"
    assert artifact.size_bytes == 12
  end

  test "download_artifact delegates to storage backend" do
    previous = Application.get_env(:crucible_model_registry, :storage_backend)

    Application.put_env(
      :crucible_model_registry,
      :storage_backend,
      CrucibleModelRegistry.Storage.Mock
    )

    on_exit(fn -> Application.put_env(:crucible_model_registry, :storage_backend, previous) end)

    artifact = insert(:artifact, storage_path: "remote/path", storage_backend: :tinker)

    CrucibleModelRegistry.Storage.Mock
    |> expect(:download, fn "remote/path", _local_path, _opts -> :ok end)

    assert :ok = CrucibleModelRegistry.download_artifact(artifact, "/tmp/local")
  end
end
