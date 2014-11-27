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

        columns_cfg.each do |col_cfg|
        end
      end

      storage
    end

  end
end
