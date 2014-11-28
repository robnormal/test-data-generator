require "rspec"
require_relative "../lib/directed_graph.rb"

describe "DirectedGraph" do
  describe :add! do
    it 'adds an edge to the graph' do
      g = DirectedGraph.new([['a', 'b']])

      expect(g.edge_count).to eq(1)
      expect(g.vertex_count).to eq(2)
    end
  end

  describe :add_edge! do
    it 'adds a GraphEdge to the graph' do
      g = DirectedGraph.new
      g.add_edge!(GraphEdge.new('a', 'b'))

      expect(g.edge_count).to eq(1)
      expect(g.vertex_count).to eq(2)
    end
  end

  describe :from_edges do
    it 'creates DirectedGraph from a list of GraphEdges' do
      g = DirectedGraph.from_edges([
        GraphEdge.new('a', 'b'),
        GraphEdge.new('b', 'c'),
        GraphEdge.new('c', 'a')
      ])

      expect(g.edge_count).to eq(3)
    end
  end

  describe :edge_count do
    it 'returns the number of edges' do
      g = DirectedGraph.new([
        ['a', 'b'],
        ['a', 'c']
      ])

      expect(g.edge_count).to eq(2)
    end
  end

  describe :vertex_count do
    it 'returns the number of vertices' do
      g = DirectedGraph.new([
        ['a', 'b'],
        ['a', 'c']
      ])

      expect(g.vertex_count).to eq(3)
    end
  end

  describe :has_cycles? do
    it 'determines whether the graph has any cycles' do
      g = DirectedGraph.new([
        ['a', 'b'],
        ['a', 'c'],
        ['b', 'c']
      ])

      expect(g.has_cycles?).to be false

      h = DirectedGraph.new([
        ['a', 'b'],
        ['c', 'a'],
        ['b', 'c']
      ])

      expect(h.has_cycles?).to be true
    end
  end

  describe :sorted do
    it 'returns the nodes in linearized order; if graph is acyclic, it is a topological sort' do
      g = DirectedGraph.new([
        ['a', 'b'],
        ['d', 'e'],
        ['c', 'd'],
        ['b', 'e'],
        ['a', 'c'],
        ['b', 'd']
      ])

      expect(g.sorted).to eq(['e','d','c','b','a']).or eq(['e','d','b','c','a'])
    end
  end
end


