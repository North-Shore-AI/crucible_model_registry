defmodule CrucibleModelRegistry.Lineage do
  @moduledoc "Lineage graph operations and persistence."

  import Ecto.Query

  alias CrucibleModelRegistry.Lineage.Graph
  alias CrucibleModelRegistry.Repo
  alias CrucibleModelRegistry.Schemas.{LineageEdge, ModelVersion}

  @doc "Returns all ancestors for a model version."
  @spec ancestors(ModelVersion.t()) :: [ModelVersion.t()]
  def ancestors(%ModelVersion{id: id}) do
    graph = build_graph()
    ids = Graph.ancestors(graph, id)
    load_versions(ids)
  end

  @doc "Returns all descendants for a model version."
  @spec descendants(ModelVersion.t()) :: [ModelVersion.t()]
  def descendants(%ModelVersion{id: id}) do
    graph = build_graph()
    ids = Graph.descendants(graph, id)
    load_versions(ids)
  end

  @doc "Adds a lineage edge if it would not create a cycle."
  @spec add_edge(map()) :: {:ok, LineageEdge.t()} | {:error, term()}
  def add_edge(attrs) when is_map(attrs) do
    source_id = Map.fetch!(attrs, :source_version_id)
    target_id = Map.fetch!(attrs, :target_version_id)

    with :ok <- ensure_acyclic(source_id, target_id) do
      %LineageEdge{}
      |> LineageEdge.changeset(attrs)
      |> Repo.insert()
    end
  end

  @doc "Checks whether adding an edge would create a cycle."
  @spec would_create_cycle?(integer(), integer()) :: boolean()
  def would_create_cycle?(source_id, target_id) do
    graph = build_graph()
    Graph.path?(graph, target_id, source_id)
  end

  defp ensure_acyclic(source_id, target_id) do
    if would_create_cycle?(source_id, target_id) do
      {:error, :cycle_detected}
    else
      :ok
    end
  end

  defp build_graph do
    LineageEdge
    |> Repo.all()
    |> Graph.build()
  end

  defp load_versions([]), do: []

  defp load_versions(ids) do
    ModelVersion
    |> where([v], v.id in ^ids)
    |> Repo.all()
  end
end
