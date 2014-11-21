require 'forgery'
require(File.dirname(__FILE__) + '/Generator.rb')
require(File.dirname(__FILE__) + '/Table.rb')

module TestDataGenerator
  class Column
    attr_reader :name, :table

    def initialize(table, name, generator, options = {})
      if generator.is_a? Generator
        if options[:null]
          @generator = NullGenerator.new generator
        else
          @generator = generator
        end
      else
        raise ArgumentError, "Argument 3 for Column.new must be a Generator"
      end

      @table   = table
      @name    = name.to_sym
      @options = options
      @values_produced = 0
    end

    def generate_one
      if being_selected_from?
        @last = @data[@values_produced]
      else
        @last = @generator.first
      end

      @values_produced += 1
      @last
    end

    def current
      generate_one until @values_produced >= @table.rows_produced

      if being_selected_from?
        @data[@table.rows_produced - 1]
      else
        @last
      end
    end

    def all
      if being_selected_from?
        @data
      else
        raise "Column::all() called on uncached column #{@table.name}.#{@name}"
      end
    end

    private
    @table
    @name
    @values_produced
    @generator
    @options
    @last

    @being_selected_from
    @data

    def generate_all
      count = @table.num_rows
      data = @generator.take count
      data
    end

    def being_selected_from?
      # only run on first call
      if @being_selected_from == nil
        @being_selected_from = @table.need_all? self

        if @being_selected_from
          @data = generate_all
          @data.freeze
          @values_produced = 0
        end
      end

      @being_selected_from
    end

  end
end

=begin
require "yaml"
config = YAML::load_file(File.dirname(__FILE__) + '/config.yml')
tables = config.map do |table, info|
  t = TestDataGenerator::Table.new table, info['rows']

  info['columns'].each do |c, col_def|
    case c
    when 'id'
      t.add c, :id
    when 'created_at'
      t.add c, :datetime
    when 'updated_at'
      if info['columns']['created_at']
        t.add c, :datetime, :greater_than => [t.to_sym, :created_at]
      else
        t.add c, :datetime
      end
    else
      unless col_def
        raise "No config info for #{t}.#{c}"
      end

      # if just a scalar, assume it is the column type
      if col_def.is_a? String
        t.add c, col_def.to_sym
      else
        unique       = col_def.delete 'unique'
        greater_than = col_def.delete 'greater_than'

        # only one entry can be left, or else the file is invalid
        if col_def.size == 1
          type, args = col_def.first
          args ||= []

          if args.is_a? Array
            t.add c, type.to_sym, *args
          else
            t.add c, type.to_sym, args
          end
        else
          raise "Unknown column info: " + col_def.keys.to_s
        end
      end
    end
  end

  t
end
=end

