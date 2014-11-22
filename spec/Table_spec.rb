require "rspec"
require_relative "../lib/Table.rb"

module TestDataGenerator
  describe Table do
    dummy = Table.new('dummy', 10)

    it 'has symbol attribute "name"' do
      expect(dummy.name).to eq(:dummy)
    end

    it 'has int attribute "num_rows"' do
      expect(dummy.num_rows).to eq(10)
    end

    it 'has int attribute "rows_produced"' do
      expect(dummy.rows_produced).to eq(0)
    end

    age = Column.new(dummy, 'age', NumberGenerator.new(min: 18, max: 100))
    it '"add" adds a column, "column" retrieves one by name' do
      dummy.add age
      expect(dummy.column(:age)).to eq(age)
    end

    describe 'add_from_spec' do
      it 'adds a column via Column.from_spec()' do
        dummy.add_from_spec(:tries, :number, max: 10)
        expect(dummy.column(:tries).generate_one).to be_between(0, 10)
      end
    end

    describe 'current' do
      it "returns column's most recently created value" do
        my_age = dummy.column(:age).generate_one
        expect(dummy.current :age).to eq(my_age)
      end
    end

    def test_row(row)
      expect(row.length).to eq(2)

      age, tries = *row
      expect(age).to be_between(18, 100)
      expect(tries).to be_between(0, 10)
    end

    describe 'row' do
      it 'generates a full row' do
        dummy.clear
        10.times do
          test_row dummy.row
        end
      end
    end

    describe 'each' do
      it 'iterates over all rows, producing as needed' do
        dummy.clear
        count = 0

        dummy.each do |row|
          test_row row
          count += 1
        end

        expect(count).to eq(10)
      end
    end

    describe :initialize do
      it 'accepts an array of column specs as the third argument' do
        users = TestDataGenerator::Table.new 'users', 3, [
          [:id],
          [:name, :forgery, [:name, :first_name]],
          [:title, :words, 2..4],
          [:created_at]
        ]

        row = users.row
        id, name, title, created_at = *row

        expect(id).to be_a(Fixnum)
        expect(name).to be_a(String)
        expect(title).to be_a(String)
        expect(created_at).to be_a(Fixnum)
      end
    end

    describe 'Table.table' do
      it 'gets table by name' do
        expect(Table.table(:dummy)).to eq(dummy)
      end
    end

  end
end


