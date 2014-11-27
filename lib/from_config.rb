module TestDataGenerator
  def self.from_config(config)
    ConfigProcess.from_config(config)
  end

  module ConfigProcess
    def self.from_config(db_cfg)
      db = Database.new

      db_cfg.each do |table, table_cfg|
        rows, column_cfgs = *table_cfg

        tbl = Table.new(table, self.columns_from_config(column_cfgs, db))
        db.add_table!(tbl, rows)
      end

      db
    end

    def self.columns_from_config(cfgs, db)
      cfgs.map { |cfg|
        name, type, args, options = *cfg
        args ||= []
        options ||= {}

        if dependent_column?(type, args, options)
          options[:db] = db
        end

        Column.from_spec(name, type, args, options)
      }
    end

    def self.dependent_column?(type, args, options)
      if type == :belongs_to
        true
      else
        false
      end
    end

  end
end
