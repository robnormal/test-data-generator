require 'forgery'

# maps a Hash to a Hash in the obvious way
def hash_map(h, &blk)
  Hash[*(h.map &blk).flatten(1)]
end

# run the block n times, and return the output as an array
def iterate n
  data = []
  n.times { data << yield }
  data
end

# choose random element from an Enumerable
def rand_in xs
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
        if @null && rand < @null
          yield nil
        else

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
    end

    # how often generator should return nil
    def set_null percent
      @null = percent
    end

    protected
    @unique
    @null

    def generate_one
      raise NotImplementedError, "Define #{self.class}::generate_one()"
    end

    def process_options options
      options ||= {}
      options = hash_map(options) { |k, v| [k.to_sym, v] }

      @unique = options && options[:unique]
      if @unique
        @data_tracker = {}
      end

      options
    end

    private
    @data_tracker
  end

  class ForgeryGenerator < Generator
    def initialize forgery_args, options = nil
      f_class = forgery_args[0].to_sym
      f_method = forgery_args[1].to_sym
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
        rand(@count)
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
      options = process_options options

      @chars = options[:chars] || WORD_CHARS

      if options[:length].is_a? Range
        options[:min_length] = options[:length].min
        options[:max_length] = options[:length].max
        options.delete :length
      end

      if options[:length]
        @length = options[:length]
      elsif options[:max_length]
        @min_length = options[:min_length] || 1
        @max_length = options[:max_length]
      else
        raise ArgumentError, "#{self.class} requires :length or :max_length option"
      end
    end

    protected

    def generate_one
      if @length
        length = @length
      else
        length = rand_between(@min_length, @max_length)
      end

      (iterate(length) { rand_in(@chars) }).join
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

      rand_between(min, @max)
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
      options = super

      if options && options[:count]
        @count = options[:count]
      elsif @unique
        raise ArgumentError, 'Unique EnumGenerator requires a :count option - the total number of values expected'
      end
    end

    private
    @set
  end

  class UrlGenerator < Generator
    def initialize options = nil
      @forgery = Forgery(:internet)
    end

    def generate_one
      domain = @forgery.send :domain_name
      'http://' + domain
    end
  end

  class BelongsToGenerator < EnumGenerator
    def initialize table, column, options = nil
      @table = table.to_sym
      @column = column.to_sym

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

