require "rspec"
require_relative "eventually"
require_relative "../lib/weighted_picker"

module TestDataGenerator
  describe WeigtedPicker do
    it 'chooses from a collection with weighted odds' do
      w = WeigtedPicker.new(a: 2, b: 4)
      expect { w.pick }.to eventually be :a
      expect { w.pick }.to eventually be :b
    end
  end
end

