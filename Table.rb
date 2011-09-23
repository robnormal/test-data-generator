class Table
  attr_reader :name, :rows_produced, :num_rows

  def initialize name, num_rows
    @name          = name.to_sym
    @num_rows      = num_rows
    @columns       = {}
    @rows_produced = 0
    @data          = {}

    @@tables[name.to_sym] = self
  end

  def add column_name, type, *args
    case type
    when :forgery
      generator = ForgeryGenerator.new   *args
    when :words
      generator = WordGenerator.new      *args
    when :enum
      options = enum_options args.last

      generator = EnumGenerator.new      options
    when :belongs_to
      table   = args[0][0]
      column  = args[0][1]
      options = enum_options args[1]

      @@need_all << [table, column]

      generator = BelongsToGenerator.new table, column, options
    when :string
      generator = StringGenerator.new    *args
    when :datetime
      generator = DateTimeGenerator.new  *args
    when :id
      generator = NumberGenerator.new    :unique => true, :min => 1, :max => 2147483647
    else
      raise ArgumentError, "Unknown generator type: #{type}"
    end

    @columns[column_name.to_sym] = Column.new self, column_name.to_sym, generator
  end

  def column column_name
    @columns[column_name]
  end

  def current column_name
    @columns[column_name].current
  end

  def all column_name
    @columns[column_name].all
  end

  def self.current table_name, column_name
    @@tables[table_name].current column_name
  end

  def self.all table_name, column_name
    @@tables[table_name].all column_name
  end

  def self.table table_name
    @@tables[table_name]
  end

  def need_all? column
    @@need_all.include? [@name, column.name]
  end

  def add_value column_name, value
    @data[column_name] ||= []
    @data[column_name] << value
  end

  def each_row
    @num_rows.times { yield row }
  end

  def row
    @rows_produced += 1
    @columns.values.map &:generate_one
  end

  private
  @@tables = {}
  @@need_all = []

  @columns
  @num_rows
  @rows_produced
  @data

  def enum_options options
    options ||= {}

    if options[:unique]
      options[:count] = @num_rows
    end

    options
  end
end


