require_relative 'Table'
require_relative 'directed_graph'
require_relative 'util'

module TestDataGenerator
  # represents an entire database worth of data
  # acts as a Mediator between different Tables and Columns
  class Database
    attr_reader :name, :table_names

    # @param name [String]
    # @param table_limits [Hash{Table => Integer}]
    #   Tables with the total number of entries to be generated for them
    def initialize(name, tables)
      @name = name
      @tables = {}
      @table_names = []

      tables.each do |table|
        @tables[table.name] = table
        @table_names << table.name
      end

      if dependency_graph.has_cycles?
        raise(ArgumentError, 'tables have circular dependencies')
      end
    end

    def generate_for(table)
      check_table table
      @tables[table].generate
    end

    def needs_for(table, data)
      check_table table
      @tables[table].needs(data)
    end

    private

    def check_table(tbl)
      if @tables[tbl].nil?
        raise(ArgumentError, "Unknown table: #{tbl}")
      end
    end

    def dependency_graph
      if @dep_graph.nil?
        @dep_graph = DirectedGraph.new(
          @tables.map { |k, table| table.dependencies_as_edges }.flatten
        )
      end

      @dep_graph
    end
  end
end

