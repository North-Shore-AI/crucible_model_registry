defmodule CrucibleModelRegistry.Storage.Utils do
  @moduledoc "Shared helpers for storage backends."

  @doc "Compute SHA256 checksum for a file."
  @spec checksum(Path.t()) :: String.t()
  def checksum(path) do
    path
    |> File.read!()
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
  end

  @doc "Return size in bytes for a file."
  @spec size_bytes(Path.t()) :: integer()
  def size_bytes(path) do
    File.stat!(path).size
  end

  @doc "Ensure parent directory exists."
  @spec ensure_parent_dir(Path.t()) :: :ok
  def ensure_parent_dir(path) do
    path
    |> Path.dirname()
    |> File.mkdir_p!()
  end
end
