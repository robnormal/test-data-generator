require_relative 'Table'
require_relative 'weighted_picker'
require_relative 'directed_graph'
require_relative 'util'
require_relative 'columnwise_storage'

module TestDataGenerator
  # represents an entire database worth of data
  # acts as a Mediator between different Tables and Columns
  class Database
    attr_reader :name, :data

    # @param name [String]
    # @param table_limits [Hash{Table => Integer}]
    #   Tables with the total number of entries to be generated for them
    def initialize(name, table_limits)
      @name = name
      @tables = {}
      @limits = {}

      table_limits.each do |table, limit|
        @tables[table.name] = table
        @limits[table.name] = limit
      end

      # allows dependent Columns to query the data they need
      # without allowing them access to the full Database
      @data = ColumnwiseStorage.new(@tables.keys)

      if dependency_graph.has_cycles?
        raise(ArgumentError, 'tables have circular dependencies')
      end

      create_thresholds
    end

    def generate!
      # pick table at random (weighted odds), and return what it generates
      @table_picker.fmap(&:pick).fmap do |table|
        generate_for(table)
      end
    end

    def generate_all!
      until generate!.nothing?; end
    end

    # maybe get rid of?
    def reset!
      @data.reset!
    end

    def create_belongs_to(column_id)
      BelongsToGenerator.new(@data, column_id)
    end

    private

    def generate_for(table)
      fulfill_needs table

      @data.append_row!(table, @tables[table].generate)

      if space_left(table) <= 0
        @limits.delete table
        create_thresholds
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

    def fulfill_needs(table)
      t = @tables[table]

      t.needs(@data).each do |source_id, num|
        # If row cannot be created, needs are unfulfillable, so bail
        if space_left(table) < num
          raise(RuntimeError, "Unable to fulfill requirements for " +
            "#{table} due to dependency on #{source_id.table}")
        end

        num.times do
          generate_for(source_id.table)
        end
      end
    end

    def space_left(table)
      @limits[table] - @data.height(table)
    end

    def create_thresholds
      @table_picker =
        if @limits.empty?
          Maybe.nothing
        else
          Maybe.just(WeigtedPicker.new @limits)
        end
    end
  end
end

