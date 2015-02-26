module TestDataGenerator
  def self.make_database(config)
    DatabaseFactory.make_database(config)
  end

  module DatabaseFactory
    def self.make_database(db_cfg)
      db = Database.new

      db_cfg.each do |table, table_cfg|
        rows, column_cfgs = *table_cfg

        tbl = Table.new(table, self.make_columns(column_cfgs, db))
        db.add_table!(tbl, rows)
      end

      db
    end

    # [table] Table this Column will belong to
    # [name] name to give to the Column
    # [type] Symbol designating Column type
    # [args] Additional arguments, depending on type
    def self.make_column(name, type_sym = nil, args = [], options = {})
      name = name.to_sym
      type = spec_type(type_sym, name)
      generator = spec_generator(type, args)

      if type == :id
        # id should be unique integer
        options[:unique] = true
      end

      generator = use_spec_options(generator, options)

      Column.new(name.to_sym, generator)
    end

    private

    def self.dependent_column?(type, args, options)
      if type == :belongs_to
        true
      else
        false
      end
    end

    def self.make_columns(cfgs, db)
      cfgs.map { |cfg|
        name, type, args, options = *cfg
        args ||= []
        options ||= {}

        if dependent_column?(type, args, options)
          options[:db] = db
        end

        make_column(name, type, args, options)
      }
    end

    def self.spec_type(type, name)
      # name-based type magic
      case name
      when :id
        :id
      when /_at$/
        :datetime
      else
        type
      end
    end

    def self.spec_generator(type, args)
      case type
      when :string
        StringGenerator.new(*args)
      when :number
        self.make_greater_than(NumberGenerator.new(*args), args)
      when :datetime
        self.make_greater_than(DateTimeGenerator.new(*args), args)
      when :forgery
        ForgeryGenerator.new(*args)
      when :words
        WordGenerator.new(*args)
      when :url
        UrlGenerator.new(*args)
      when :enum
        EnumGenerator.new(*args)
      when :bool, :boolean
        NumberGenerator.new(min: 0, max: 1)
      when :belongs_to
        BelongsToGenerator.new(ColumnId.new(*args))
      when :id
        NumberGenerator.new(min: 1, max: 2147483647)
      else
        raise ArgumentError, "Unknown generator type: #{type}"
      end
    end

    def self.make_greater_than(gen, args)
      if args.first && args.first[:greater_than]
        GreaterThanGenerator.new(gen, args.first[:greater_than])
      else
        gen
      end
    end

    def self.use_spec_options(generator, opts)
      if opts[:unique]
        generator = generator.to_unique
      end

      # null must come after unique, since NULL is not a "unique" value
      if opts[:null]
        generator = NullGenerator.new(generator, opts[:null])
      end

      generator
    end
  end
end
