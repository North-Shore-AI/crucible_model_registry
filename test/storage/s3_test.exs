defmodule CrucibleModelRegistry.Storage.S3Test do
  use CrucibleModelRegistry.DataCase, async: true

  alias CrucibleModelRegistry.Storage.S3
  alias CrucibleModelRegistry.Storage.S3ClientMock

  test "upload delegates to client and returns checksum" do
    tmp_dir = Path.join(System.tmp_dir!(), "cmr-s3-#{System.unique_integer([:positive])}")
    File.mkdir_p!(tmp_dir)
    source_path = Path.join(tmp_dir, "model.bin")
    File.write!(source_path, "s3-data")

    S3ClientMock
    |> expect(:put_object, fn "bucket", "path/model.bin", "s3-data", _opts ->
      {:ok, :uploaded}
    end)

    assert {:ok, %{checksum: checksum, size_bytes: 7}} =
             S3.upload(source_path, "s3://bucket/path/model.bin", client: S3ClientMock)

    assert checksum == Base.encode16(:crypto.hash(:sha256, "s3-data"), case: :lower)
  end

  test "presigned_url delegates to client" do
    S3ClientMock
    |> expect(:presigned_url, fn "bucket", "path/model.bin", 300, _opts ->
      {:ok, "https://example.com/url"}
    end)

    assert {:ok, "https://example.com/url"} =
             S3.presigned_url("s3://bucket/path/model.bin", 300, client: S3ClientMock)
  end

  test "exists? returns false on not_found" do
    S3ClientMock
    |> expect(:head_object, fn "bucket", "missing.bin", _opts ->
      {:error, :not_found}
    end)

    refute S3.exists?("s3://bucket/missing.bin", client: S3ClientMock)
  end
end
