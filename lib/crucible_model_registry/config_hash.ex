defmodule CrucibleModelRegistry.ConfigHash do
  @moduledoc "Canonical hashing for training configurations."

  @doc "Compute SHA256 hash of a canonicalized config."
  @spec hash_config(map()) :: String.t()
  def hash_config(config) when is_map(config) do
    config
    |> normalize()
    |> Jason.encode!()
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
  end

  defp normalize(%_{} = struct) do
    struct
    |> Map.from_struct()
    |> normalize()
  end

  defp normalize(map) when is_map(map) do
    map
    |> Enum.map(fn {key, value} -> {to_string(key), normalize(value)} end)
    |> Enum.sort_by(fn {key, _value} -> key end)
    |> Jason.OrderedObject.new()
  end

  defp normalize(list) when is_list(list) do
    Enum.map(list, &normalize/1)
  end

  defp normalize(value), do: value
end
