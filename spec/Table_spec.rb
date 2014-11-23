require "rspec"
require_relative "../lib/Table.rb"

module TestDataGenerator
  describe Table do
    dummy = Table.new('dummy')

    it 'has symbol attribute "name"' do
      expect(dummy.name).to eq(:dummy)
    end

    age = Column.new('age', NumberGenerator.new(min: 18, max: 100))
    it '"add" adds a column, "column" retrieves one by name' do
      dummy.add! age
      expect(dummy.column(:age)).to eq(age)
    end

    describe 'add_from_spec' do
      it 'adds a column via Column.from_spec()' do
        dummy.add_from_spec!(:tries, :number, [max: 10])
        expect(dummy.column(:tries).generate).to be_between(0, 10)
      end
    end

    def test_row(row)
      expect(row.length).to eq(2)

      age, tries = *row
      expect(age).to be_between(18, 100)
      expect(tries).to be_between(0, 10)
    end

    describe 'generate' do
      it 'generates a full row' do
        10.times do
          test_row dummy.generate
        end
      end
    end

    describe :initialize do
      it 'accepts an array of column specs as the third argument' do
        users = TestDataGenerator::Table.new 'users', [
          [:id],
          [:name, :forgery, [:name, :first_name]],
          [:title, :words, [2..4]],
          [:created_at]
        ]

        row = users.generate
        id, name, title, created_at = *row

        expect(id).to be_a(Fixnum)
        expect(name).to be_a(String)
        expect(title).to be_a(String)
        expect(created_at).to be_a(Fixnum)
      end
    end

  end
end


