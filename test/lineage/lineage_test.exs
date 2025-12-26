defmodule CrucibleModelRegistry.LineageTest do
  use CrucibleModelRegistry.DataCase, async: true

  alias CrucibleModelRegistry.Lineage

  test "returns ancestors and descendants" do
    v1 = insert(:model_version, config_hash: "hash-1")
    v2 = insert(:model_version, config_hash: "hash-2")
    v3 = insert(:model_version, config_hash: "hash-3")

    {:ok, _} =
      Lineage.add_edge(%{
        source_version_id: v1.id,
        target_version_id: v2.id,
        relationship: :fine_tuned_from
      })

    {:ok, _} =
      Lineage.add_edge(%{
        source_version_id: v2.id,
        target_version_id: v3.id,
        relationship: :fine_tuned_from
      })

    ancestors = Lineage.ancestors(v3) |> Enum.map(& &1.id) |> Enum.sort()
    descendants = Lineage.descendants(v1) |> Enum.map(& &1.id) |> Enum.sort()

    assert ancestors == Enum.sort([v1.id, v2.id])
    assert descendants == Enum.sort([v2.id, v3.id])
  end

  test "detects cycles when adding edges" do
    v1 = insert(:model_version, config_hash: "hash-4")
    v2 = insert(:model_version, config_hash: "hash-5")
    v3 = insert(:model_version, config_hash: "hash-6")

    {:ok, _} =
      Lineage.add_edge(%{
        source_version_id: v1.id,
        target_version_id: v2.id,
        relationship: :fine_tuned_from
      })

    {:ok, _} =
      Lineage.add_edge(%{
        source_version_id: v2.id,
        target_version_id: v3.id,
        relationship: :fine_tuned_from
      })

    assert {:error, :cycle_detected} =
             Lineage.add_edge(%{
               source_version_id: v3.id,
               target_version_id: v1.id,
               relationship: :fine_tuned_from
             })
  end
end
