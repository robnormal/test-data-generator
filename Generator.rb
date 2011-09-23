def iterate n
  data = []
  n.times { data << yield }
  data
end

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

module TestDataGenerator
  class Generator
    include Enumerable

    def each
      loop do
        if @unique
          begin
            value = generate_one
          end while @data_tracker[value]

          @data_tracker[value] = true
          yield value
        else
          yield generate_one
        end
      end
    end

    protected
    @unique

    def generate_one
      raise NotImplementedError, "Define #{self.class}::generate_one()"
    end

    def process_options options
      @unique = options && options[:unique]
      if @unique
        @data_tracker = {}
      end
    end

    private
    @data_tracker
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

    def each
      if @unique
        yield generate_one
      else
        super
      end
    end

    protected

    def generate_one
      if @unique
        if !@data
          @data = @set.sample(@count)
        end

        if @data.empty?
          raise ArgumentError, "Ran out of data: #{@table.name}.#{@name}"
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
end

