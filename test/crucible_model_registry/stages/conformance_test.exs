defmodule CrucibleModelRegistry.Stages.ConformanceTest do
  @moduledoc """
  Conformance tests for all model registry stages.

  Verifies that all stages implement the Crucible.Stage behaviour correctly
  with canonical describe/1 schema format.
  """
  use ExUnit.Case

  alias CrucibleModelRegistry.Stages.{
    Promote,
    Register
  }

  @stages [
    Register,
    Promote
  ]

  describe "all model registry stages implement describe/1" do
    for stage <- @stages do
      test "#{inspect(stage)} has describe/1" do
        assert function_exported?(unquote(stage), :describe, 1)
      end

      test "#{inspect(stage)} returns valid schema" do
        schema = unquote(stage).describe(%{})
        assert is_atom(schema.name)
        assert is_binary(schema.description)
        assert is_list(schema.required)
        assert is_list(schema.optional)
        assert is_map(schema.types)
      end

      test "#{inspect(stage)} has types for all required fields" do
        schema = unquote(stage).describe(%{})

        for key <- schema.required do
          assert Map.has_key?(schema.types, key),
                 "Required field #{key} missing from types"
        end
      end

      test "#{inspect(stage)} has types for all optional fields" do
        schema = unquote(stage).describe(%{})

        for key <- schema.optional do
          assert Map.has_key?(schema.types, key),
                 "Optional field #{key} missing from types"
        end
      end

      test "#{inspect(stage)} has no overlap between required and optional" do
        schema = unquote(stage).describe(%{})

        overlap =
          MapSet.intersection(
            MapSet.new(schema.required),
            MapSet.new(schema.optional)
          )

        assert MapSet.size(overlap) == 0
      end

      test "#{inspect(stage)} has valid type specifications" do
        schema = unquote(stage).describe(%{})

        for {key, type_spec} <- schema.types do
          assert valid_type_spec?(type_spec),
                 "Invalid type spec for :#{key}: #{inspect(type_spec)}"
        end
      end
    end
  end

  describe "stage-specific schemas" do
    test "register has expected required fields" do
      schema = Register.describe(%{})
      assert schema.name == :model_register
      assert :model_name in schema.required
      assert :recipe in schema.required
      assert :base_model in schema.required
      assert schema.types.lineage_type == {:enum, [:fine_tune, :distillation, :merge]}
    end

    test "promote has expected required fields" do
      schema = Promote.describe(%{})
      assert schema.name == :model_promote
      assert :stage in schema.required
      assert schema.types.stage == {:enum, [:development, :staging, :production, :archived]}
    end
  end

  # Type specification validation helpers
  @primitive_types [:string, :integer, :float, :boolean, :atom, :map, :list, :module, :any]

  defp valid_type_spec?(spec) when spec in @primitive_types, do: true
  defp valid_type_spec?({:struct, mod}) when is_atom(mod), do: true
  defp valid_type_spec?({:enum, values}) when is_list(values), do: true
  defp valid_type_spec?({:list, inner}), do: valid_type_spec?(inner)
  defp valid_type_spec?({:map, k, v}), do: valid_type_spec?(k) and valid_type_spec?(v)
  defp valid_type_spec?({:function, arity}) when is_integer(arity) and arity >= 0, do: true

  defp valid_type_spec?({:union, types}) when is_list(types),
    do: Enum.all?(types, &valid_type_spec?/1)

  defp valid_type_spec?({:tuple, types}) when is_list(types),
    do: Enum.all?(types, &valid_type_spec?/1)

  defp valid_type_spec?(_), do: false
end
