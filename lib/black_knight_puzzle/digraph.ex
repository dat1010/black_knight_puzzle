defmodule BlackKnightPuzzle.Digraph do
  def create_graph do
    :digraph.new()
  end

  def add_vertex(graph, vertex) do
    :digraph.add_vertex(graph, vertex)
  end

  def add_edge(graph, from_vertex, to_vertex) do
    :digraph.add_edge(graph, from_vertex, to_vertex)
  end

  def vertices(graph) do
    :digraph.vertices(graph)
  end

  def edges(graph) do
    :digraph.edges(graph)
  end

  def delete(graph) do
    :digraph.delete(graph)
  end

  def info(graph) do
    :digraph.info(graph)
  end
end
