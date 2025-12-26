defmodule CrucibleModelRegistry.Storage.HuggingFaceTest do
  use CrucibleModelRegistry.DataCase, async: true

  alias CrucibleModelRegistry.Storage.HuggingFace
  alias CrucibleModelRegistry.Storage.HuggingFaceClientMock

  test "upload delegates to client" do
    tmp_dir = Path.join(System.tmp_dir!(), "cmr-hf-#{System.unique_integer([:positive])}")
    File.mkdir_p!(tmp_dir)
    source_path = Path.join(tmp_dir, "model.bin")
    File.write!(source_path, "hf-data")

    HuggingFaceClientMock
    |> expect(:upload, fn ^source_path, "org/model", _opts ->
      {:ok, %{checksum: "checksum", size_bytes: 7}}
    end)

    assert {:ok, %{checksum: "checksum", size_bytes: 7}} =
             HuggingFace.upload(source_path, "org/model", client: HuggingFaceClientMock)
  end

  test "presigned_url delegates to client" do
    HuggingFaceClientMock
    |> expect(:presigned_url, fn "org/model", 600, _opts ->
      {:ok, "https://hf.co/org/model"}
    end)

    assert {:ok, "https://hf.co/org/model"} =
             HuggingFace.presigned_url("org/model", 600, client: HuggingFaceClientMock)
  end
end
