defmodule CrucibleModelRegistry.Storage.LocalTest do
  use CrucibleModelRegistry.DataCase, async: true

  alias CrucibleModelRegistry.Storage.Local

  test "uploads, downloads, and deletes artifacts locally" do
    tmp_dir = Path.join(System.tmp_dir!(), "cmr-local-#{System.unique_integer([:positive])}")
    File.mkdir_p!(tmp_dir)

    source_path = Path.join(tmp_dir, "source.bin")
    File.write!(source_path, "local-data")

    assert {:ok, %{checksum: checksum, size_bytes: 10}} =
             Local.upload(source_path, "models/v1.bin", base_path: tmp_dir)

    stored_path = Path.join(tmp_dir, "models/v1.bin")
    assert File.exists?(stored_path)
    assert checksum == Base.encode16(:crypto.hash(:sha256, "local-data"), case: :lower)

    download_path = Path.join(tmp_dir, "download.bin")
    assert :ok = Local.download("models/v1.bin", download_path, base_path: tmp_dir)
    assert File.read!(download_path) == "local-data"

    assert Local.exists?("models/v1.bin", base_path: tmp_dir)
    assert :ok = Local.delete("models/v1.bin", base_path: tmp_dir)
    refute Local.exists?("models/v1.bin", base_path: tmp_dir)
  end
end
