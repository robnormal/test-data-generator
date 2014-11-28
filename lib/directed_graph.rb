class DirectedGraph
  def self.from_edges(edges)
    graph = DirectedGraph.new
    edges.each do |edge| graph.add_edge!(edge) end
    graph
  end

  def initialize(edges = [])
    @edges = []
    @nodes = {}
    @pre = {}
    @post = {}
    @sorted = []

    edges.each do |edge|
      add!(*edge)
    end
  end

  def add!(from, to)
    add_edge!(GraphEdge.new(from, to))
  end

  def add_edge!(edge)
    @edges << edge

    if !@nodes[edge.from]
      @nodes[edge.from] = []
    end
    if !@nodes[edge.to]
      @nodes[edge.to] = []
    end
    @nodes[edge.from] << edge.to
    @has_dfs = false
  end

  def vertex_count
    @nodes.length
  end

  def edge_count
    @edges.length
  end

  def pre
    dfs
    @pre
  end

  def post
    dfs
    @post
  end

  def sorted
    dfs
    @sorted
  end

  def has_cycles?
    dfs
    # look for "backward" edge
    @edges.any? { |edge|
      @pre[edge.to] < @pre[edge.from] && @post[edge.to] > @post[edge.from]
    }
  end

  private
  def dfs
    unless @has_dfs
      @unsearched = @nodes.keys

      until @unsearched.empty?
        dfs_node(@unsearched.first, 0)
      end

      @has_dfs = true
    end
  end

  def dfs_node(start, time)
    @pre[start] = time
    @unsearched.delete start

    @nodes[start].each do |node|
      if @pre[node].nil?
        time += 1
        @pre[node] = time
        time = dfs_node(node, time) + 1
      end
    end
    @post[start] = time
    @sorted << start

    time
  end
end

class GraphEdge
  attr_reader :from, :to

  def initialize(from, to)
    @from = from
    @to = to
  end
end

