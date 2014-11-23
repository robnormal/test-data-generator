require_relative('data_generators.rb')
require_relative('Table.rb')
require_relative('weighted_picker.rb')

module TestDataGenerator
  class Database
    attr_reader :name, :data

    # @param name [String]
    # @param table_limits [Hash{Table => Fixnum}]
    #   Tables with the total number of entries to be generated for them
    def initialize(name, table_limits)
      @name = name
      @tables = {}
      @limits = {}
      @data = {}

      table_limits.each do |table, limit|
        @tables[table.name] = table
        @limits[table.name] = limit
      end

      if dependency_graph.has_cycles?
        raise(ArgumentError, 'tables have circular dependencies')
      end

      create_thresholds
    end

    def generate!
      # pick table at random (weighted odds), and return what it generates
      table = @table_picker.pick
      if table.nil?
        false
      else
        @data[table] << @tables[table].generate

        if @data[table].length >= @limits[table]
          @limits.delete table
          create_thresholds
        end

        true
      end
    end

    def generate_all!
      until generate!.nil?; end
    end

    def dependency_graph
      if @dep_graph.nil?
        dependencies = []
        @tables.each do |table|
          dependencies += table.dependencies
        end

        @dep_graph = DirectedGraph.new dependencies
      end

      @dep_graph
    end

    private

    def create_thresholds
      @table_picker = WeigtedPicker.new(@limits)
    end

    # call when table fills up
    def table_filled(table)
      # ignore this table when picking tables
      @limits.delete table
      create_thresholds
    end
  end
end

