require "rspec"
require_relative "../lib/column"
require_relative "shared"
require 'set'

module TestDataGenerator
  describe Column do
    before :example do
      @num = Column.new('age', NumberGenerator.new(min: 18, max: 100))
    end

    it 'has symbol attribute "name"' do
      expect(@num.name).to eq(:age)
    end

    describe :generate! do
      it 'uses given generator to produce one datum' do
        expect(@num.generate!).to be_between(18, 100)
      end
    end

    describe :data do
      it 'retrieves generated data' do
        3.times { @num.generate! }

        expect(@num.data.length).to be 3
      end
    end

    describe :reset! do
      it 'deletes generated data' do
        3.times { @num.generate! }
        @num.reset!

        expect(@num.data.length).to be 0
      end
    end
  end

end

