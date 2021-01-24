RSpec.describe PgSeedDump::TableConfiguration::Base do
  let(:schema) { instance_double("PgSeedDump::Schema") }

  describe ".new" do
    it "raises an error if table doesn't exist" do
      expect { described_class.new(schema, "users2") }.to raise_error(
        PgSeedDump::Schema::TableNotExistsError,
        "Table users2 doesn't exist"
      )
    end

    it "initializes correctly" do
      table_configuration = described_class.new(schema, "users")
      expect(table_configuration.table_name).to eq :users
      expect(table_configuration.foreign_keys).to be_empty
    end
  end
end
