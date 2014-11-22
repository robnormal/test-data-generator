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

    def self.from_spec(table, name, type, *args)
      # name-based type magic
      case name
      when :id
        type = :id
      when /_at$/
        type = :datetime
      end

      case type
      when :string
        generator = StringGenerator.new(*args)
      when :number
        generator = NumberGenerator.new(*args)
      when :datetime
        generator = DateTimeGenerator.new(*args)
      when :forgery
        generator = ForgeryGenerator.new(*args)
      when :words
        generator = WordGenerator.new(*args)
      when :url
        generator = UrlGenerator.new(*args)
      when :bool, :boolean
        generator = NumberGenerator.new(min: 0, max: 1)
      when :enum
        generator = EnumGenerator.new(args.last)
      when :id
        # id should be unique integer
        args << :unique
        generator = NumberGenerator.new(min: 1, max: 2147483647)
      when :belongs_to
        foreign_table  = args[0][0].to_sym
        foreign_column = args[0][1].to_sym
        options        = args[1] || {}

        generator = BelongsToGenerator.new(foreign_table, foreign_column, options)
      else
        raise ArgumentError, "Unknown generator type: #{type}"
      end

      if args.include?(:unique) && !generator.handles_unique?
        generator = UniqueGenerator.new(generator)
      end

      # null must come after unique, since NULL is not a "unique" value
      if args.include?(:null)
        generator = NullGenerator.new(generator)
      end

      optional_args = if args.last.is_a?(Hash) then args.last else {} end

      if type == :belongs_to
        ForeignColumn.new(table, name.to_sym, generator, optional_args)
      else
        Column.new(table, name.to_sym, generator, optional_args)
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

  class ForeignColumn < Column
    attr_reader :foreign_table, :foreign_column

    # generator must be a BelongsToGenerator
    def initialize(table, name, generator, options = {})
      super
      @foreign_table = generator.table
      @foreign_column = generator.column
    end
  end
end

