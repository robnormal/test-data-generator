module TestDataGenerator
  def self.from_config(config)
    ConfigProcess.from_config(config)
  end

  module ConfigProcess
    def self.from_config(db_cfg)
      db = Database.new([])
      storage = ColumnwiseStorage.new(db, fmap(db_cfg, &:first))

      db_cfg.each do |table, table_cfg|
        rows, columns_cfg = *table_cfg

        db.add_table! Table.new(table, self.columns_from_config(table_cfg))
      end

      storage
    end

    def self.columns_from_config(cfg)
      name, type, args, options = *cfg
      []
    end

  end
end
