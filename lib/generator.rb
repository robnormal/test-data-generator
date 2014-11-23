module TestDataGenerator
  module Generator
    # @return One generated value
    def generate; raise NotImplementedError end

    def iterate(n)
      (1..n).collect { generate }
    end

    def to_unique
      UniqueGenerator.new self
    end
  end
end

