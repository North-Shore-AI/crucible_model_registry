defmodule CrucibleModelRegistry.Pins.ArtifactPin do
  @moduledoc "Immutable descriptor for a pinned artifact bundle."

  alias CrucibleModelRegistry.ProviderCompatibility
  alias CrucibleModelRegistry.Pins.RequiredFile

  @enforce_keys [:version, :repo_id, :revision, :manifest_sha256, :files]
  defstruct [
    :version,
    :repo_id,
    :revision,
    :manifest_sha256,
    :files,
    provider_compatibility: [],
    metadata: %{}
  ]

  @type t :: %__MODULE__{
          version: pos_integer(),
          repo_id: String.t(),
          revision: String.t(),
          manifest_sha256: String.t(),
          files: [RequiredFile.t()],
          provider_compatibility: [ProviderCompatibility.t()],
          metadata: map()
        }

  @supported_version 1

  @doc "Loads a pin descriptor from a JSON file."
  @spec load(Path.t()) :: {:ok, t()} | {:error, Exception.t()}
  def load(path) when is_binary(path) do
    {:ok, load!(path)}
  rescue
    exception -> {:error, exception}
  end

  @doc "Loads a pin descriptor from a JSON file, raising on invalid input."
  @spec load!(Path.t()) :: t()
  def load!(path) when is_binary(path) do
    path
    |> File.read!()
    |> Jason.decode!()
    |> new!()
  end

  @doc "Builds a pin descriptor from a decoded JSON map."
  @spec new(map()) :: {:ok, t()} | {:error, Exception.t()}
  def new(attrs) when is_map(attrs) do
    {:ok, new!(attrs)}
  rescue
    exception -> {:error, exception}
  end

  @doc "Builds a pin descriptor from a decoded JSON map, raising on invalid input."
  @spec new!(map()) :: t()
  def new!(attrs) when is_map(attrs) do
    version = required_integer!(attrs, "version")

    unless version == @supported_version do
      raise ArgumentError,
            "artifact pin carries unsupported version #{inspect(version)}; expected #{@supported_version}"
    end

    files =
      attrs
      |> required_list!("files")
      |> Enum.map(&RequiredFile.new!/1)

    validate_duplicate_paths!(files)

    manifest_sha256 = attrs |> required_string!("manifest_sha256") |> String.downcase()
    RequiredFile.validate_sha256!(manifest_sha256, "manifest_sha256")
    validate_manifest_file!(files, manifest_sha256)

    %__MODULE__{
      version: version,
      repo_id: required_string!(attrs, "repo_id"),
      revision: required_string!(attrs, "revision"),
      manifest_sha256: manifest_sha256,
      files: files,
      provider_compatibility: provider_compatibility(attrs),
      metadata: optional_map(attrs, "metadata")
    }
  end

  @spec validate_compatibility(t(), map() | keyword() | ProviderCompatibility.t()) ::
          {:ok, ProviderCompatibility.t()} | {:error, {:incompatible_provider, [term()]}}
  def validate_compatibility(%__MODULE__{} = pin, requirement) do
    ProviderCompatibility.validate(pin.provider_compatibility, requirement)
  end

  defp validate_duplicate_paths!(files) do
    files
    |> Enum.map(& &1.path)
    |> Enum.frequencies()
    |> Enum.find(fn {_path, count} -> count > 1 end)
    |> case do
      nil -> :ok
      {path, _count} -> raise ArgumentError, "duplicate required file path #{inspect(path)}"
    end
  end

  defp validate_manifest_file!(files, manifest_sha256) do
    case Enum.find(files, &(&1.path == "manifest.json")) do
      nil ->
        :ok

      %{sha256: ^manifest_sha256} ->
        :ok

      %{sha256: file_sha256} ->
        raise ArgumentError,
              "manifest_sha256 #{manifest_sha256} does not match manifest.json file sha256 #{file_sha256}"
    end
  end

  defp required_string!(attrs, key) do
    case field(attrs, key) do
      value when is_binary(value) and value != "" -> value
      _ -> raise ArgumentError, "missing required artifact pin key #{inspect(key)}"
    end
  end

  defp required_integer!(attrs, key) do
    case field(attrs, key) do
      value when is_integer(value) -> value
      _ -> raise ArgumentError, "missing required artifact pin key #{inspect(key)}"
    end
  end

  defp required_list!(attrs, key) do
    case field(attrs, key) do
      [_ | _] = value -> value
      _ -> raise ArgumentError, "missing required artifact pin key #{inspect(key)}"
    end
  end

  defp provider_compatibility(attrs) do
    attrs
    |> optional_list("provider_compatibility")
    |> Enum.map(&ProviderCompatibility.new!/1)
  end

  defp optional_list(attrs, key) do
    case field(attrs, key) do
      nil -> []
      value when is_list(value) -> value
      _ -> raise ArgumentError, "#{key} must be a list"
    end
  end

  defp optional_map(attrs, key) do
    case field(attrs, key) do
      nil -> %{}
      value when is_map(value) -> value
      _ -> raise ArgumentError, "#{key} must be a map"
    end
  end

  defp field(attrs, "version"), do: Map.get(attrs, "version", Map.get(attrs, :version))
  defp field(attrs, "repo_id"), do: Map.get(attrs, "repo_id", Map.get(attrs, :repo_id))
  defp field(attrs, "revision"), do: Map.get(attrs, "revision", Map.get(attrs, :revision))
  defp field(attrs, "files"), do: Map.get(attrs, "files", Map.get(attrs, :files))

  defp field(attrs, "provider_compatibility"),
    do: Map.get(attrs, "provider_compatibility", Map.get(attrs, :provider_compatibility))

  defp field(attrs, "metadata"), do: Map.get(attrs, "metadata", Map.get(attrs, :metadata))

  defp field(attrs, "manifest_sha256"),
    do: Map.get(attrs, "manifest_sha256", Map.get(attrs, :manifest_sha256))
end
