module TestDataGenerator
  module Generator
    # @return One generated value
    def generate; raise NotImplementedError end

    def to_unique
      UniqueGenerator self
    end
  end
end

