defmodule CrucibleModelRegistry.Query.Filters do
  @moduledoc "Filter implementations for model version queries."

  import Ecto.Query

  @doc "Apply a list of filters to an Ecto query."
  @spec apply_filters(Ecto.Queryable.t(), list()) :: Ecto.Query.t()
  def apply_filters(query, filters) do
    Enum.reduce(filters, query, fn filter, acc ->
      apply_filter(acc, filter)
    end)
  end

  @doc "Check whether a model join is required."
  @spec needs_model_join?(list()) :: boolean()
  def needs_model_join?(filters) do
    Enum.any?(filters, fn
      {:model_name, _} -> true
      {:tag, _} -> true
      _ -> false
    end)
  end

  defp apply_filter(query, {:stage, stage}) do
    where(query, [v], v.stage == ^stage)
  end

  defp apply_filter(query, {:recipe, recipe}) do
    where(query, [v], v.recipe == ^recipe)
  end

  defp apply_filter(query, {:base_model, base_model}) do
    where(query, [v], v.base_model == ^base_model)
  end

  defp apply_filter(query, {:model_name, model_name}) do
    where(query, [model: m], m.name == ^model_name)
  end

  defp apply_filter(query, {:tag, tag}) do
    where(query, [model: m], fragment("? = ANY(?)", ^tag, m.tags))
  end

  defp apply_filter(query, {:metric, metric_name, op, value}) do
    case op do
      :gt ->
        where(query, [v], fragment("(? ->> ?)::float > ?", v.metrics, ^metric_name, ^value))

      :gte ->
        where(query, [v], fragment("(? ->> ?)::float >= ?", v.metrics, ^metric_name, ^value))

      :lt ->
        where(query, [v], fragment("(? ->> ?)::float < ?", v.metrics, ^metric_name, ^value))

      :lte ->
        where(query, [v], fragment("(? ->> ?)::float <= ?", v.metrics, ^metric_name, ^value))

      :eq ->
        where(query, [v], fragment("(? ->> ?)::float = ?", v.metrics, ^metric_name, ^value))

      _ ->
        query
    end
  end

  defp apply_filter(query, _filter), do: query
end
