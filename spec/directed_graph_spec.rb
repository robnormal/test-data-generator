require "rspec"
require_relative "../lib/directed_graph.rb"

describe "DirectedGraph" do
  describe :add! do
    it 'adds an edge to the graph' do
      g = DirectedGraph.new
      g.add!('a', 'b')

      expect(g.edge_count).to eq(1)
      expect(g.vertex_count).to eq(2)
    end
  end

  describe :has_cycles? do
    it 'determines whether the graph has any cycles' do
      g = DirectedGraph.new
      g.add!('a', 'b')
      g.add!('a', 'c')
      g.add!('b', 'c')

      expect(g.has_cycles?).to be false

      h = DirectedGraph.new
      h.add!('a', 'b')
      h.add!('b', 'c')
      h.add!('c', 'a')

      expect(h.has_cycles?).to be true
    end
  end
end


