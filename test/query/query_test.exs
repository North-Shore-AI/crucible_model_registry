defmodule CrucibleModelRegistry.QueryTest do
  use CrucibleModelRegistry.DataCase, async: true

  alias CrucibleModelRegistry.Query

  test "filters by stage" do
    prod = insert(:model_version, stage: :production, config_hash: "hash-prod")
    _exp = insert(:model_version, stage: :experiment, config_hash: "hash-exp")

    results =
      %{stage: :production}
      |> Query.from_filters()
      |> Query.execute()

    assert Enum.map(results, & &1.id) == [prod.id]
  end

  test "filters by metric threshold" do
    high =
      insert(:model_version,
        metrics: %{"accuracy" => 0.95},
        config_hash: "hash-high"
      )

    _low =
      insert(:model_version,
        metrics: %{"accuracy" => 0.5},
        config_hash: "hash-low"
      )

    results =
      %{min_accuracy: 0.9}
      |> Query.from_filters()
      |> Query.execute()

    assert Enum.map(results, & &1.id) == [high.id]
  end

  test "filters by recipe and base model" do
    match =
      insert(:model_version,
        recipe: "sl_basic",
        base_model: "meta-llama/Llama-3.1-8B",
        config_hash: "hash-match"
      )

    _other =
      insert(:model_version,
        recipe: "dpo",
        base_model: "meta-llama/Llama-3.1-8B",
        config_hash: "hash-other"
      )

    results =
      %{recipe: "sl_basic", base_model: "meta-llama/Llama-3.1-8B"}
      |> Query.from_filters()
      |> Query.execute()

    assert Enum.map(results, & &1.id) == [match.id]
  end
end
