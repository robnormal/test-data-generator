require_relative "util"
require_relative 'weighted_picker'

module TestDataGenerator
  class StrictHash < Hash
    def initialize(&blk)
      if blk
        @blk = blk
      else
        @blk = ->(key) { "No such key: #{key}" }
      end
    end

    def [](key)
      val = super
      if val.nil?
        raise(IndexError, @blk.call(key))
      else
        val
      end
    end
  end

  class Database
    # @param [Database]
    def initialize(tables_limits = {})
      @tables = {}
      @limits = {}
      add_tables! tables_limits
    end

    def add_table!(table, limit)
      add_table_raw!(table, limit)
      update_table_data
    end

    def add_tables!(tables_limits)
      tables_limits.each do |table, limit|
        add_table_raw!(table, limit)
      end
      update_table_data
    end

    def retrieve(cat, subcat)
      @data[cat][subcat] || []
    end

    def retrieve_by_id(column_id)
      retrieve(column_id.table, column_id.column)
    end

    def generate!
      # pick table at random (weighted odds), and return what it generates
      @table_picker.fmap(&:pick).fmap do |table|
        generate_for! table
      end
    end

    def generate_all!
      until generate!.nothing?; end
    end

    def reset!
      @data = StrictHash.new { |table|  "No such table: #{table}" }

      @tables.each do |name, table|
        @data[name] = {}
        table.column_names.each do
          |col| @data[name][col] = []
        end
      end
    end

    # yield successive rows to block, and delete the row
    def offload!(category)
      columns = @data[category]
      len = height category

      len.times do
        yield fmap(columns, &:shift)
      end
    end

    def columns(category)
      @data[category].first && @data[category].first.keys || []
    end

    def offload_all!
      output = {}
      fmap_with_keys(@data) { |cat, column|
        to_enum(:offload!, cat).to_a
      }
    end

    def height(category)
      @data[category].empty? ? 0 : @data[category].first[1].length
    end


    private

    def add_table_raw!(table, limit)
      @tables[table.name] = table
      @limits[table.name] = limit
    end

    def update_table_data
      check_dependencies
      create_thresholds
      reset!
    end

    def generate_for!(table)
      fulfill_needs! table

      t = @tables[table]

      # gather depended-on data
      data = {}
      t.dependencies.each do |col_id|
        data[col_id.to_a] = retrieve_by_id(col_id)
      end

      generate_row(table, data)
    end

    def fulfill_needs!(table)
      @tables[table].needs(self).each do |source, num|
        # If row cannot be created, needs are unfulfillable, so bail
        if space_left(source.table) < num
          raise(RuntimeError, "Unable to fulfill requirements for " +
            "#{table} due to dependency on #{source.table}")
        end

        @data[source.table][source.column] +=
          @tables[source.table].fulfill_need(source.column, num)
      end
    end

    def space_left(table)
      (@limits[table] || 0) - height(table)
    end

    def create_thresholds
      @table_picker =
        if @limits.empty?
          Maybe.nothing
        else
          Maybe.just(WeigtedPicker.new @limits)
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

    def check_dependencies
      if dependency_graph.has_cycles?
        raise(ArgumentError, 'tables have circular dependencies')
      end
    end

    private

    def generate_row(table, data)
      @tables[table].generate(data).each do |col, value|
        @data[table][col] << value
      end

      if space_left(table) <= 0
        @limits.delete table
        create_thresholds
      end
    end

  end
end
