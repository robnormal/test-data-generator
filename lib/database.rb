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

      # if no table was picked, we're out of stuff to generate
      if table.nil?
        false
      else
        @data[table] << @tables[table].generate
        check_for_full table
        true
      end
    end

    def generate_all!
      until generate!.nil?; end
    end

    def dependency_graph
      if @dep_graph.nil?
        @dep_graph = DirectedGraph.new(@tables.map(&:dependencies).flatten)
      end

      @dep_graph
    end

    private

    def create_thresholds
      @table_picker = WeigtedPicker.new(@limits)
    end

    # stop generating rows if table is full
    def check_for_full(table)
      if @data[table].length >= @limits[table]
        @limits.delete table
        create_thresholds
      end
    end

  end
end

