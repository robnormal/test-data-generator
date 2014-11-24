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
        fulfill_needs table
        row table
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

    def row(table)
      store_rows(table, @tables[table].generate)
    end

    def store_rows(table, rows)
      @data[table] += rows
      still_has_space table
    end

    def fulfill_needs(table)
      t = @tables[table]

      # Get data for Tables this table depends on
      source_data = t.tables_depended_on.map { |table| @data[table] }

      t.needs(source_data).each do |source, num|
        # If row cannot be created, needs are unfulfillable, so bail
        if space_left(table) < num
          raise(RuntimeError, "Unable to fulfill requirements for "
            "#{source.name} due to dependency from #{table}"
          )
        end

        store_rows(table, t.iterate num)
      end
    end

    def space_left(table)
      @limits[table] - @data[table].length
    end

    def create_thresholds
      @table_picker = WeigtedPicker.new(@limits)
    end

    # stop generating rows if table is full
    def still_has_space(table)
      if @data[table].length >= @limits[table]
        @limits.delete table
        create_thresholds

        false
      else
        true
      end
    end

  end
end

