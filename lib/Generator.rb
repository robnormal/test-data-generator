require 'forgery'

# maps a Hash to a Hash in the obvious way
def hash_map(h, &blk)
  Hash[*(h.map &blk).flatten(1)]
end

# run the block n times, and return the output as an array
def iterate(n)
  data = []
  n.times { data << yield }
  data
end

# choose random element from an Enumerable
def rand_in(xs)
  xs.to_a.sample
end

# random integer between min and max _inclusively_
def rand_between(min, max)
  rand(max - min + 1) + min
end

module TestDataGenerator
  class Generator
    include Enumerable

    def each
      loop do
        yield generate_one
      end
    end

    def handles_unique?
      false
    end

    protected

    # every subclass must define
    def generate_one
      raise NotImplementedError, "Define #{self.class}::generate_one()"
    end

  end

  # Generates data using the forgery library
  class ForgeryGenerator < Generator
    def initialize(forgery_args, options = {})
      @forgery        = Forgery(forgery_args[0].to_sym)
      @forgery_method = forgery_args[1].to_sym
      @forgery_args   = forgery_args[2, -1] || []
    end

    protected
    @forgery
    @forgery_method
    @forgery_args

    def generate_one
      @forgery.send(@forgery_method, *@forgery_args)
    end
  end

  # creates lorem ipsum verbiage
  class WordGenerator < ForgeryGenerator
    def initialize(count, options = {})
      super([:lorem_ipsum, :words], options)
      @count = count
    end

    def num_words
      if @count.is_a? Integer
        @count
      else
        rand(@count)
      end
    end

    protected

    def generate_one
      @forgery.send(@forgery_method, num_words, random: true)
    end

    private
    @count
  end

  # random strings
  class StringGenerator < Generator
    ALL_CHARS  = ('!'..'z').to_a
    WORD_CHARS = ('0'..'9').to_a + ('A'..'Z').to_a + ('a'..'z').to_a << '_'

    def initialize(chars: WORD_CHARS, length: nil, min_length: 1, max_length: nil)
      @chars = chars

      if length.is_a? Range
        min_length = length.min
        max_length = length.max
        length = nil
      end

      if length
        @length = length
      elsif max_length
        @min_length = min_length
        @max_length = max_length
      else
        raise(ArgumentError, "#{self.class} requires :length or :max_length option")
      end
    end

    protected

    def generate_one
      length = @length || rand_between(@min_length, @max_length)

      (iterate(length) { rand_in @chars }).join
    end

    @min_length
    @max_length
    @length # exact length for all values
    @chars # set of characters to choose from
  end

  class NumberGenerator < Generator
    def initialize(max: nil, min: 0, greater_than: nil)
      if max
        @max = max
      else
        raise(ArgumentError, "#{self.class} requires :max option")
      end

      if greater_than
        table, column = *greater_than
        @greater_than = { table: table, column: column }
      else
        @min = min
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

      rand_between(min, @max)
    end

    @greater_than
    @min
    @max
  end

  class UrlGenerator < Generator
    def initialize(options = nil)
      @forgery = Forgery(:internet)
    end

    def generate_one
      domain = @forgery.send :domain_name
      'http://' + domain
    end
  end

  class DateTimeGenerator < NumberGenerator
    def initialize(options = {})
      options[:max] ||= Time.now().to_i

      super(options)
    end
  end

  # Decorator class
  class UniqueGenerator < Generator
    def initialize(gen, max: nil)
      @generator = gen
      @max = max
      @count = 0
      @data_tracker = {}
    end

    protected

    def generate_one
      if @max && @count >= @max
        raise(IndexError, "No more unique data; all #{@max} unique values have been used")
      else
        begin
          value = @generator.first
        end while @data_tracker[value]

        @data_tracker[value] = true
        @count += 1
        value
      end
    end

    private
    @generator
    @defer
    @data_tracker
    @max
    @count
  end

  # Decorator class
  class NullGenerator < Generator
    # null: probability of producing a null value
    def initialize(gen, null)
      @generator = gen
      @null = null
    end

    protected

    def generate_one
      if rand < @null
        nil
      else
        @generator.first
      end
    end

    private
    @generator
    @data_tracker
  end

  # for values selected from a set
  # including any column that "belongs_to" another column
  class EnumGenerator < Generator
    def handles_unique?
      true
    end

    def initialize(set, unique: false)
      @set = set.to_a
      @unique = unique
    end

    protected

    def generate_one
      if @unique
        # intialize @data, if not initialized
        if !@data
          @data = @set.uniq.shuffle
        end

        if @data.empty?
          raise(IndexError, "No more unique data")
        end

        @data.shift
      else
        @set.sample
      end
    end

    private
    @set
    @data
  end

  # selects values from a column in a table
  class BelongsToGenerator < EnumGenerator
    attr_reader :table, :column

    def initialize(table, column, options = {})
      @table = table.to_sym
      @column = column.to_sym
      @unique = options[:unique]
    end

    # wait until we need data before asking Table to generate it
    def generate_one
      unless @set
        @set = Table.all(@table, @column)
      end

      super
    end
  end
end

