defmodule CrucibleModelRegistry.Pins.RequiredFile do
  @moduledoc "A required file entry in a pinned model artifact bundle."

  @enforce_keys [:path, :sha256]
  defstruct [:path, :sha256, :size_bytes]

  @type t :: %__MODULE__{
          path: String.t(),
          sha256: String.t(),
          size_bytes: non_neg_integer() | nil
        }

  @sha256_regex ~r/^[0-9a-f]{64}$/

  @doc "Builds and validates a required file entry."
  @spec new(map()) :: {:ok, t()} | {:error, Exception.t()}
  def new(attrs) when is_map(attrs) do
    {:ok, new!(attrs)}
  rescue
    exception -> {:error, exception}
  end

  @doc "Builds and validates a required file entry, raising on invalid input."
  @spec new!(map()) :: t()
  def new!(attrs) when is_map(attrs) do
    path = required_string!(attrs, "path")
    sha256 = attrs |> required_string!("sha256") |> String.downcase()
    size_bytes = optional_size_bytes(attrs)

    validate_path!(path)
    validate_sha256!(sha256, "sha256")

    %__MODULE__{path: path, sha256: sha256, size_bytes: size_bytes}
  end

  @doc "Validates a SHA-256 hex digest."
  @spec validate_sha256!(String.t(), String.t()) :: :ok
  def validate_sha256!(sha256, field_name) when is_binary(sha256) do
    if Regex.match?(@sha256_regex, sha256) do
      :ok
    else
      raise ArgumentError, "#{field_name} must be a lowercase 64-character SHA-256 hex digest"
    end
  end

  defp validate_path!(path) do
    cond do
      path == "" ->
        raise ArgumentError, "required file path cannot be empty"

      Path.type(path) != :relative ->
        raise ArgumentError, "required file path must be relative: #{inspect(path)}"

      Enum.any?(Path.split(path), &(&1 in [".", ".."])) ->
        raise ArgumentError,
              "required file path cannot contain . or .. segments: #{inspect(path)}"

      true ->
        :ok
    end
  end

  defp required_string!(attrs, key) do
    case field(attrs, key) do
      value when is_binary(value) and value != "" ->
        value

      _ ->
        raise ArgumentError, "missing required file key #{inspect(key)}"
    end
  end

  defp optional_size_bytes(attrs) do
    case field(attrs, "size_bytes") do
      nil -> nil
      value when is_integer(value) and value >= 0 -> value
      _ -> raise ArgumentError, "size_bytes must be a non-negative integer"
    end
  end

  defp field(attrs, "path"), do: Map.get(attrs, "path", Map.get(attrs, :path))
  defp field(attrs, "sha256"), do: Map.get(attrs, "sha256", Map.get(attrs, :sha256))
  defp field(attrs, "size_bytes"), do: Map.get(attrs, "size_bytes", Map.get(attrs, :size_bytes))
end
