require "rspec"
require_relative "../lib/column"
require_relative "shared"
require 'set'

module TestDataGenerator
  describe Column do
    num = Column.new('age', NumberGenerator.new(min: 18, max: 100))

    it 'has symbol attribute "name"' do
      expect(num.name).to eq(:age)
    end

    describe 'generate' do
      it 'uses given generator to produce one datum' do
        expect(num.generate).to be_between(18, 100)
      end
    end
  end

end

