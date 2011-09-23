require 'forgery'

def rand_in *args
  unless args.all? { |x| x }
    raise ArgumentError, "nil is not an allowed argument to rand_in()"
  end

  case args.size
  when 1
    if args[0].is_a? Enumerable
      args[0].to_a.sample
    elsif args[0].is_a? Numeric
      rand args[0]
    else
      raise ArgumentError, "Improper arguments for rand_in"
    end
  when 2
    if args.all? { |x| x.is_a? Numeric }
      min = args[0]
      max = args[1]

      rand(max - min) + min
    else
      rand (args[0]..args[1]).to_a
    end
  else
    raise ArgumentError, "wrong number of (non-nil) arguments(#{args.size} for 1-2)"
  end
end

def iterate n
  data = []
  n.times { data << yield }
  data
end

def zipall as
  if as.size > 0
    as.first.zip(as[1..-1])
  else
    []
  end
end

class Column
  attr_reader :name, :last, :table

  def initialize table, name, generator, options = nil
    @table   = table
    @name    = name
    @options = options
    @values_produced = 0

    if generator.is_a? Generator
      @generator = generator
    else
      raise ArgumentError, "Argument 3 for Column.new must be a Generator"
    end
  end

  def generate_one
    if cached?
      @last = @data[@values_produced]
    else
      @last = @generator.take(1).first
    end

    @values_produced += 1
    @last
  end

  def current
    generate_one until @values_produced == @table.rows_produced
    @last
  end

  def all
    if cached?
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

  @cached
  @data

  def generate_all
    count = @table.num_rows
    data = @generator.take count
    data
  end

  def cached?
    # only run on first call
    if @cached == nil
      @cached = @table.need_all? self

      if @cached
        @data = generate_all
        @data.freeze
        @values_produced = 0
      end
    end

    @cached
  end

end

class Generator
  include Enumerable

  def each
    loop do
      if @unique
        begin
          value = generate_one
        end while @data.include? value

        @data << value
        yield value
      else
        yield generate_one
      end
    end
  end

  protected
  @unique
  @data

  def generate_one
    raise NotImplementedError, "Define #{self.class}::generate_one()"
  end

  def process_options options
    @unique = options && options[:unique]
    if @unique
      @data = []
    end
  end
end

class ForgeryGenerator < Generator
  def initialize forgery_args, options = nil
    f_class = forgery_args[0]
    f_method = forgery_args[1]
    f_args = forgery_args[2, -1]

    @forgery = Forgery(f_class)
    @forgery_method = f_method
    @forgery_args = f_args || []

    process_options options
  end

  protected
  @forgery
  @forgery_method
  @forgery_args

  def generate_one
    @forgery.send(@forgery_method, *@forgery_args)
  end
end

class WordGenerator < ForgeryGenerator
  def initialize count, options = nil
    super [:lorem_ipsum, :words], options
    @count = count
  end

  def num_words
    if @count.is_a? Integer
      @count
    else
      rand_in(@count)
    end
  end

  protected

  def generate_one
    @forgery.send(@forgery_method, num_words, :random => true)
  end

  private
  @count
end

class StringGenerator < Generator
  ALL_CHARS  = ('!'..'z').to_a
  WORD_CHARS = ('0'..'9').to_a + ('A'..'Z').to_a + ('a'..'z').to_a << '_'

  def initialize options = nil
    options ||= {}

    @chars = options[:chars] || WORD_CHARS

    if options[:length]
      @length = options[:length]
    elsif options[:max_length]
      @max_length = options[:max_length]
      @min_length = options[:min_length] || 1
    else
      raise ArgumentError, "#{self.class} requires :length or :max_length option"
    end
  end

  protected

  def generate_one
    if @length
      length = @length
    else
      length = rand_in @min_length, @max_length
    end

    (iterate(length) { rand_in @chars }).join
  end

  @min_length
  @max_length
  @length # exact length for all values
  @chars # set of characters to choose from
end

class NumberGenerator < Generator
  def initialize options = nil
    options ||= {}
    @max = options[:max]

    unless @max
      raise ArgumentError, "#{self.class} requires :max or :greater_than option"
    end

    if options[:greater_than]
      table, column = *options[:greater_than]
      @greater_than = { :table => table, :column => column }
    else
      @min = options[:min] || 0
    end
  end

  protected

  def generate_one
    if @greater_than
      current = Table.current(@greater_than[:table], @greater_than[:column]) || 0

      # enforce min requirement, if present
      if @min && @min > current
        min = @min
      else
        min = current
      end

    else
      min = @min
    end

    rand_in min, @max
  end

  @greater_than
  @min
  @max
end

# for values selected from a set
# including any column that "belongs_to" another column
class EnumGenerator < Generator
  def initialize set, options = nil
    @set = set
  end

  protected

  def generate_one
    if @is_unique
      if !@data
        @data = @set.sample(@count)
      end

      @data.shift
    else
      @set.sample
    end
  end

  def process_options options
    super
    if options && options[:count]
      @count = options[:count]
    elsif @unique
      raise ArgumentError, 'Unique EnumGenerator requires a :count option - the total number of values expected'
    end
  end

  private
  @set
end

class BelongsToGenerator < EnumGenerator
  def initialize table, column, options = nil
    @table = table
    @column = column

    process_options options
  end

  def each
    unless @set
      @set = Table.all(@table, @column)
    end

    super
  end

  private
  @table
  @column
end

class DateTimeGenerator < NumberGenerator
  MYSQL_FORMAT = 'Y-m-d H:M:S'

  def initialize options = nil
    options ||= {}
    options[:max] ||= Time.now().to_i

    super options
  end

end

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

      if options[:unique]
        @@need_all << [table, column]
      end

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

a = Table.new 'authors', 3000
a.add 'id',         :id
a.add 'first_name', :forgery, [:name, :first_name]
a.add 'last_name',  :forgery, [:name, :last_name]
a.add 'email',      :forgery, [:email, :address], :unique => true
a.add 'created_at', :datetime
a.add 'updated_at', :datetime, :greater_than => [:authors, :created_at]

b = Table.new 'books', 3000
b.add 'id',        :id
b.add 'author_id', :belongs_to, [:authors, :id]
b.add 'title',     :words, 2..4
b.add 'isbn',      :string, :length => 20

c = Table.new 'phone_numbers', 3000
c.add 'author_id', :belongs_to, [:authors, :id], :unique => true
c.add 'number', :string, :length => 10, :chars => ('0'..'9')

[a,b,c].each { |t| t.each_row { |row| p row } }

