defmodule CrucibleModelRegistry.Pins.FetcherVerifierTest do
  use ExUnit.Case, async: true

  alias CrucibleModelRegistry.Pins.{ArtifactPin, Fetcher, Receipt, Verifier}

  @now ~U[2026-05-22 00:00:00Z]

  test "fetches files and returns a receipt" do
    %{pin: pin, source: source, dest: dest} = fixture_bundle()

    assert {:ok, %Receipt{} = receipt} =
             Fetcher.fetch(pin, dest,
               downloader: local_downloader(source),
               now: fn -> @now end
             )

    assert receipt.action == :fetch
    assert receipt.repo_id == pin.repo_id
    assert receipt.revision == pin.revision
    assert receipt.destination == Path.expand(dest)
    assert Enum.map(receipt.files, & &1.status) == [:fetched, :fetched]
    assert File.read!(Path.join(dest, "manifest.json")) == "manifest"
    assert File.read!(Path.join(dest, "checkpoints/a.safetensors")) == "tensor"
  end

  test "skips already verified files unless force is set" do
    %{pin: pin, source: source, dest: dest} = fixture_bundle()

    assert {:ok, _receipt} = Fetcher.fetch(pin, dest, downloader: local_downloader(source))

    assert {:ok, receipt} =
             Fetcher.fetch(pin, dest,
               downloader: fn _args ->
                 raise "downloader should not be called for verified files"
               end
             )

    assert Enum.map(receipt.files, & &1.status) == [:skipped, :skipped]

    File.write!(Path.join(dest, "manifest.json"), "stale")

    assert {:ok, forced} =
             Fetcher.fetch(pin, dest, downloader: local_downloader(source), force: true)

    assert Enum.map(forced.files, & &1.status) == [:fetched, :fetched]
    assert File.read!(Path.join(dest, "manifest.json")) == "manifest"
  end

  test "verifies a fetched artifact bundle" do
    %{pin: pin, source: source, dest: dest} = fixture_bundle()

    assert {:ok, _receipt} = Fetcher.fetch(pin, dest, downloader: local_downloader(source))
    assert {:ok, %Receipt{} = receipt} = Verifier.verify(pin, dest, now: fn -> @now end)

    assert receipt.action == :verify
    assert Enum.map(receipt.files, & &1.status) == [:verified, :verified]
  end

  test "returns a checksum mismatch instead of silently accepting bad files" do
    %{pin: pin, source: source, dest: dest} = fixture_bundle()

    assert {:ok, _receipt} = Fetcher.fetch(pin, dest, downloader: local_downloader(source))
    File.write!(Path.join(dest, "manifest.json"), "bad")

    assert {:error, {:checksum_mismatch, "manifest.json", _expected, _actual}} =
             Verifier.verify(pin, dest)
  end

  defp fixture_bundle do
    root = Path.join(System.tmp_dir!(), "cmr-pins-#{System.unique_integer([:positive])}")
    source = Path.join(root, "source")
    dest = Path.join(root, "dest")

    write!(Path.join(source, "manifest.json"), "manifest")
    write!(Path.join(source, "checkpoints/a.safetensors"), "tensor")

    {:ok, pin} =
      ArtifactPin.new(%{
        "version" => 1,
        "repo_id" => "example/repo",
        "revision" => "abc123",
        "manifest_sha256" => sha256(Path.join(source, "manifest.json")),
        "files" => [
          %{"path" => "manifest.json", "sha256" => sha256(Path.join(source, "manifest.json"))},
          %{
            "path" => "checkpoints/a.safetensors",
            "sha256" => sha256(Path.join(source, "checkpoints/a.safetensors"))
          }
        ]
      })

    %{pin: pin, source: source, dest: dest}
  end

  defp local_downloader(source) do
    fn args ->
      path = Keyword.fetch!(args, :path)
      {:ok, Path.join(source, path)}
    end
  end

  defp write!(path, body) do
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, body)
  end

  defp sha256(path) do
    path
    |> File.read!()
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
  end
end
