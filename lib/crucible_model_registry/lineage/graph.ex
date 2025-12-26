defmodule CrucibleModelRegistry.Lineage.Graph do
  @moduledoc "Wrapper around libgraph for lineage traversal."

  alias Graph

  @type t :: Graph.t()

  @doc "Builds a directed graph from lineage edges."
  @spec build([CrucibleModelRegistry.Schemas.LineageEdge.t()]) :: t()
  def build(edges) do
    Enum.reduce(edges, Graph.new(type: :directed), fn edge, graph ->
      Graph.add_edge(graph, edge.source_version_id, edge.target_version_id)
    end)
  end

  @doc "Returns descendant vertex ids."
  @spec descendants(t(), term()) :: [term()]
  def descendants(graph, node_id) do
    traverse(graph, node_id, &Graph.out_neighbors/2)
  end

  @doc "Returns ancestor vertex ids."
  @spec ancestors(t(), term()) :: [term()]
  def ancestors(graph, node_id) do
    traverse(graph, node_id, &Graph.in_neighbors/2)
  end

  @doc "Checks if a path exists between two nodes."
  @spec path?(t(), term(), term()) :: boolean()
  def path?(graph, from, to) do
    descendants(graph, from) |> Enum.member?(to)
  end

  defp traverse(graph, node_id, neighbor_fun) do
    do_traverse([node_id], MapSet.new([node_id]), neighbor_fun, graph, [])
    |> Enum.reverse()
  end

  defp do_traverse([], _visited, _neighbor_fun, _graph, acc), do: acc

  defp do_traverse([node | rest], visited, neighbor_fun, graph, acc) do
    neighbors = neighbor_fun.(graph, node)

    {visited, queue, acc} =
      Enum.reduce(neighbors, {visited, rest, acc}, fn neighbor,
                                                      {visited_acc, queue_acc, acc_acc} ->
        if MapSet.member?(visited_acc, neighbor) do
          {visited_acc, queue_acc, acc_acc}
        else
          {
            MapSet.put(visited_acc, neighbor),
            queue_acc ++ [neighbor],
            [neighbor | acc_acc]
          }
        end
      end)

    do_traverse(queue, visited, neighbor_fun, graph, acc)
  end
end
