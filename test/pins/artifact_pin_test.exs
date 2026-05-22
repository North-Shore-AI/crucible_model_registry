defmodule CrucibleModelRegistry.Pins.ArtifactPinTest do
  use ExUnit.Case, async: true

  alias CrucibleModelRegistry.Pins.{ArtifactPin, RequiredFile}

  @fixture Path.expand("../fixtures/trinity_artifact_pin.json", __DIR__)

  test "loads the canonical TRINITY artifact pin fixture" do
    assert {:ok, %ArtifactPin{} = pin} = ArtifactPin.load(@fixture)

    assert pin.version == 1
    assert pin.repo_id == "nshkrdotcom/trinity-coordinator-adapted-qwen3-0.6b"
    assert pin.revision == "v1.0.0"

    assert pin.manifest_sha256 ==
             "2a1476a4d2c7b66633232a564114dfb7ebe46f6bea624fc9ae9123678cafcbb9"

    assert length(pin.files) == 11

    assert %RequiredFile{
             path: "manifest.json",
             sha256: "2a1476a4d2c7b66633232a564114dfb7ebe46f6bea624fc9ae9123678cafcbb9"
           } = hd(pin.files)
  end

  test "rejects a pin with no revision" do
    attrs =
      @fixture
      |> File.read!()
      |> Jason.decode!()
      |> Map.delete("revision")

    assert {:error, %ArgumentError{message: message}} = ArtifactPin.new(attrs)
    assert message =~ "revision"
  end

  test "rejects a pin with no manifest checksum" do
    attrs =
      @fixture
      |> File.read!()
      |> Jason.decode!()
      |> Map.delete("manifest_sha256")

    assert {:error, %ArgumentError{message: message}} = ArtifactPin.new(attrs)
    assert message =~ "manifest_sha256"
  end

  test "rejects duplicate required file paths" do
    attrs =
      @fixture
      |> File.read!()
      |> Jason.decode!()
      |> Map.update!("files", fn [first | _] -> [first, first] end)

    assert {:error, %ArgumentError{message: message}} = ArtifactPin.new(attrs)
    assert message =~ "duplicate required file path"
  end
end
