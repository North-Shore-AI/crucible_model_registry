defmodule CrucibleModelRegistry.Query do
  @moduledoc "Query builder for model versions."

  import Ecto.Query, except: [order_by: 2, order_by: 3, limit: 2, offset: 2, preload: 2]
  require Ecto.Query

  alias CrucibleModelRegistry.Query.Filters
  alias CrucibleModelRegistry.Schemas.ModelVersion

  defp repo, do: CrucibleModelRegistry.repo()

  defstruct filters: [], order_by: nil, limit: nil, offset: nil, preloads: []

  @type t :: %__MODULE__{
          filters: list(),
          order_by: {atom(), atom()} | nil,
          limit: non_neg_integer() | nil,
          offset: non_neg_integer() | nil,
          preloads: list()
        }

  @doc "Builds a new query."
  @spec new() :: t()
  def new, do: %__MODULE__{}

  @doc "Builds a query from a filter map."
  @spec from_filters(map()) :: t()
  def from_filters(filters) when is_map(filters) do
    Enum.reduce(filters, new(), fn {key, value}, query ->
      apply_filter(query, key, value)
    end)
  end

  @doc "Executes a query and returns model versions."
  @spec execute(t()) :: [ModelVersion.t()]
  def execute(%__MODULE__{} = query) do
    base = from(v in ModelVersion)

    base =
      if Filters.needs_model_join?(query.filters) do
        from v in base, join: m in assoc(v, :model), as: :model
      else
        base
      end

    base
    |> Filters.apply_filters(query.filters)
    |> apply_order(query.order_by)
    |> apply_limit(query.limit)
    |> apply_offset(query.offset)
    |> apply_preloads(query.preloads)
    |> repo().all()
  end

  @doc "Filter by stage."
  @spec where_stage(t(), atom()) :: t()
  def where_stage(%__MODULE__{} = query, stage),
    do: add_filter(query, {:stage, stage})

  @doc "Filter by training recipe."
  @spec where_recipe(t(), String.t()) :: t()
  def where_recipe(%__MODULE__{} = query, recipe),
    do: add_filter(query, {:recipe, recipe})

  @doc "Filter by base model."
  @spec where_base_model(t(), String.t()) :: t()
  def where_base_model(%__MODULE__{} = query, base_model),
    do: add_filter(query, {:base_model, base_model})

  @doc "Filter by model name."
  @spec where_model_name(t(), String.t()) :: t()
  def where_model_name(%__MODULE__{} = query, model_name),
    do: add_filter(query, {:model_name, model_name})

  @doc "Filter by tag."
  @spec where_tag(t(), String.t()) :: t()
  def where_tag(%__MODULE__{} = query, tag),
    do: add_filter(query, {:tag, tag})

  @doc "Filter by metric value."
  @spec where_metric(t(), String.t(), atom(), number()) :: t()
  def where_metric(%__MODULE__{} = query, metric_name, operator, value),
    do: add_filter(query, {:metric, metric_name, operator, value})

  @doc "Order query results."
  @spec order_by(t(), atom(), atom()) :: t()
  def order_by(%__MODULE__{} = query, field, direction \\ :asc),
    do: %__MODULE__{query | order_by: {field, direction}}

  @doc "Limit query results."
  @spec limit(t(), non_neg_integer()) :: t()
  def limit(%__MODULE__{} = query, limit),
    do: %__MODULE__{query | limit: limit}

  @doc "Offset query results."
  @spec offset(t(), non_neg_integer()) :: t()
  def offset(%__MODULE__{} = query, offset),
    do: %__MODULE__{query | offset: offset}

  @doc "Preload associations."
  @spec preload(t(), list()) :: t()
  def preload(%__MODULE__{} = query, preloads),
    do: %__MODULE__{query | preloads: preloads}

  defp apply_filter(query, :stage, value), do: where_stage(query, value)
  defp apply_filter(query, :recipe, value), do: where_recipe(query, value)
  defp apply_filter(query, :base_model, value), do: where_base_model(query, value)
  defp apply_filter(query, :model_name, value), do: where_model_name(query, value)
  defp apply_filter(query, :tag, value), do: where_tag(query, value)
  defp apply_filter(query, :min_accuracy, value), do: where_metric(query, "accuracy", :gte, value)
  defp apply_filter(query, :max_accuracy, value), do: where_metric(query, "accuracy", :lte, value)

  defp apply_filter(query, :metric, {name, op, value}),
    do: where_metric(query, name, op, value)

  defp apply_filter(query, _key, _value), do: query

  defp add_filter(%__MODULE__{} = query, filter),
    do: %__MODULE__{query | filters: [filter | query.filters]}

  defp apply_order(query, nil), do: query

  defp apply_order(query, {field, direction}) do
    Ecto.Query.order_by(query, [v], [{^direction, field(v, ^field)}])
  end

  defp apply_limit(query, nil), do: query
  defp apply_limit(query, limit), do: Ecto.Query.limit(query, ^limit)

  defp apply_offset(query, nil), do: query
  defp apply_offset(query, offset), do: Ecto.Query.offset(query, ^offset)

  defp apply_preloads(query, []), do: query
  defp apply_preloads(query, preloads), do: Ecto.Query.preload(query, ^preloads)
end
