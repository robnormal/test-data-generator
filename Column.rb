require 'forgery'

def rand_in *args
  unless args.all? { |x| x }
    raise ArgumentError, "nil is not an allowed argument to rand_in()"
  end

  case args.size
  when 1
    if args[0].is_a? Enumerable
      set = args[0].to_a
      set[rand set.size]
    elsif args[0].is_a? Numeric
      rand args[0]
    else
      raise ArgumentError, "Improper arguments for rand_in"
    end
  when 2
    if args.any? { |x| x.is_a? Numeric }
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

    if generator.is_a? Generator
      @generator = generator
    else
      raise ArgumentError, "Argument 3 for Column.new must be a Generator"
    end
  end

  def generate_one
    @last = @generator.generate_one
  end

  private
  @table
  @name
  @generator
  @options
  @last
end

class Generator

  def generate n
    if @unique
      unique(n) &:generate_one
    else
      iterate(n) &:generate_one
    end
  end

  def unique n, &func
    while @data.size < n do
      datum = func[]
      @data << datum unless @data.include?
    end
    @data
  end

  def unique_reset
    @data = []
  end

  def generate_one
    raise NotImplementedError, "Define #{self.class}::generate_one()"
  end

  protected
  @unique
  @data
end

class ForgeryGenerator < Generator
  def initialize forgery_type, forgery_method, *args
    @forgery = Forgery(forgery_type)
    @forgery_method = forgery_method
    @forgery_args = args
  end

  def generate_one
    if @forgery_args.size
      @forgery.send(@forgery_method, *@forgery_args)
    else
      @forgery.send(@forgery_method)
    end
  end

  protected
  @forgery
  @forgery_method 
  @forgery_args 
end

class WordGenerator < ForgeryGenerator
  def initialize count
    super :basic, :words
    @count = count
  end

  def num_words
    if @count.is_a? Integer
      @count
    else
      rand_in(@count)
    end
  end

  def generate_one
    @forgery.send(@forgery_method, num_words)
  end

  private
  @count
end

class StringGenerator < Generator
  ALL_CHARS  = ('!'..'z').to_a
  WORD_CHARS = ('0'..'9').to_a + ('A'..'Z').to_a + ('a'..'z').to_a << '_'

  def initialize options = nil
    super
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

  def generate_one
    if @length
      length = @length
    else
      length = rand_in @min_length, @max_length
    end

    iterate(length) { rand_in @chars }
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

  def generate_one
    if @greater_than
      current = Table.current(@greater_than[:table], @greater_than[:column]) || 0
      min = if current > @min then current else @min end # make sure to enforce this rule!
    else
      min = @min
    end

      p @max, min, @greater_than
    rand_in min, @max
  end

  protected
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

  private
  @set
end

class BelongsToGenerator < Generator
  def initialize table, column, options = nil
    @table = table
    @column = column
  end

  def generate n
    options = Table.all(table, column)
    EnumGenerator.new(options).generate n
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

  def generate n
    map(super) { Time.new(n).strftime(MYSQL_FORMAT) }
  end

end

class Table
  attr_reader :name

  def initialize name, num_rows
    @name          = name
    @num_rows      = num_rows
    @columns       = {}
    @rows_produced = 0
    @data          = {}

    @@tables[name.to_sym] = self
  end

  def add column_name, type, *args
    case type
    when :forgery
      forgery_args = args.first
      generator = ForgeryGenerator.new   forgery_args[0], forgery_args[1], *forgery_args[2,-1]
    when :belongs_to
      generator = BelongsToGenerator.new args[0][0], args[0][1], args[1]
    when :string
      generator = StringGenerator.new    args[0]
    when :datetime
      generator = DateTimeGenerator.new  args[0]
    when :id
      generator = NumberGenerator.new    :unique => true, :min => 1, :max => 2147483647
    end

    @columns[column_name.to_sym] = Column.new self, column_name, generator
  end

  def current column_name
    @columns[column_name].last
  end

  def all column_name
    @columns[column_name].generate @num_rows
  end

  def self.current table_name, column_name
    @@tables[table_name].current column_name
  end

  def self.all table_name, column_name
    @@table_name[table_name].all column_name
  end

  def each_row
    yield row
  end

  def row
    @rows_produced += 1
    # record column data, and return row
    zipall(@columns.values.map { |c| @data[c.name] = c.generate_one })
  end

  private
  @@tables = {}
  @columns
  @num_rows
  @rows_produced
  @data
end

a = Table.new 'authors', 100
a.add 'id',         :id
a.add 'first_name', :forgery, [:name, :first_name]
a.add 'last_name',  :forgery, [:name, :last_name]
a.add 'email',      :forgery, [:email, :address], :unique => true
a.add 'created_at', :datetime
a.add 'updated_at', :datetime, :greater_than => [:authors, :created_at]

b = Table.new 'books', 100
a.add 'id',        :id
a.add 'author_id', :belongs_to, [:authors, :id]
a.add 'title',     :words, 2..4
a.add 'isbn',      :string, :length => 20

[a,b].each { |t| t.each_row { |row| puts row } }

