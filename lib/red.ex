defmodule Red do
  @doc ~S"""
    Returns a node.

    ## Examples

    iex> Red.node(1)
    %Red.Node{id: 1}

    iex> Red.node({:user, 42})
    %Red.Node{class: :user, id: 42}

    iex> Red.node("user#42")
    %Red.Node{class: "user", id: "42"}

    iex> Red.node("key")
    %Red.Node{id: "key"}

    iex> %Red.Node{id: 1} |> Red.node
    %Red.Node{id: 1}
  """
  def node(n), do: Red.Node.build(n)

  @doc ~S"""
    Returns a relation.

    ## Examples

    iex> "user#42" |> Red.rel(:follow)
    %Red.Rel{
      name: :follow,
      direction: :out,
      node: %Red.Node{class: "user", id: "42"}
    }

    iex> {:user, 42} |> Red.rel(:follow, :in)
    %Red.Rel{
      name: :follow,
      direction: :in,
      node: %Red.Node{class: :user, id: 42}
    }
  """
  def rel(node, name, direction \\ :out) when direction in [:in, :out] do
    %Red.Rel{
      name: name,
      direction: direction,
      node: Red.node(node)
    }
  end

  def edge(%Red.Rel{} = rel, target_node) do
    %Red.Edge{
      rel: rel,
      target: Red.node(target_node)
    }
  end

  def query(%Red.Rel{} = rel) do
    %Red.Query{queryable: rel}
  end

  def key(x), do: Red.Key.build(x)

  def limit(%Red.Rel{} = rel, limit) do
    %{query(rel) | meta: %Red.Query.Meta{limit: limit}}
  end

  def limit(%Red.Query{} = query, limit) do
    %{query | meta: %{query.meta | limit: limit}}
  end

  def offset(%Red.Rel{} = rel, offset) do
    %{query(rel) | meta: %Red.Query.Meta{offset: offset}}
  end

  def offset(%Red.Query{} = query, offset) do
    %{query | meta: %{query.meta | offset: offset}}
  end

  def add!(%Red.Rel{} = rel, end_nodes) when is_list(end_nodes) do
    end_nodes
    |> Stream.map(&Red.edge rel, &1)
    |> Stream.map(&Red.Edge.ops &1, :add)
    |> Enum.reduce(&(&2 ++ &1))
    |> Red.Client.pipeline_exec
  end

  def add!(%Red.Rel{} = rel, end_node) do
    rel
    |> Red.edge(end_node)
    |> Red.Edge.ops(:add)
    |> Red.Client.pipeline_exec
  end
end
