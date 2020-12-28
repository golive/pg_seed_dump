RSpec.describe PgSeedDump::Configuration do
  subject { described_class.new }

  describe "initializer" do
    it "returns empty configurations" do
      expect(subject.seed_table_configurations).to eq []
      expect(subject.full_table_configurations).to eq []
      expect(subject.partial_table_configurations).to eq []
    end
  end

  shared_examples "common examples" do |type|
    it "raises error if table doesn't exist" do
      expect { subject.public_send(type, "inexistent_table") }.to raise_error(
        PgSeedDump::Configuration::TableNotExistsError,
        "Table inexistent_table doesn't exist"
      )
    end

    it "stores #{type} configuration for existent table" do
      configuration = subject.public_send(type, "users")
      expect(subject.public_send("#{type}_table_configurations")).to eq [configuration]
    end

    it "yields the created configuration if a block is given" do
      subject.public_send(type, "users") do |config|
        expect(config).to be_an_instance_of(
          PgSeedDump::TableConfiguration.const_get(type.capitalize)
        )
        expect(config.table_name).to eq :users
      end
    end

    it "raises error if table already configured" do
      subject.public_send(type, "users")
      expect { subject.public_send(type, "users") }.to raise_error(
        PgSeedDump::Configuration::TableAlreadyDefinedError,
        "Table users has been already defined"
      )
    end

    it "accepts multipe tables" do
      users_configuration = subject.public_send(type, "users")
      blog_posts_configuration = subject.public_send(type, "blog_posts")

      expect(subject.public_send("#{type}_table_configurations")).to include(
        users_configuration, blog_posts_configuration
      )
    end
  end

  describe "#full" do
    it_behaves_like "common examples", "full"
  end

  describe "#partial" do
    it_behaves_like "common examples", "partial"
  end

  describe "#seed" do
    it_behaves_like "common examples", "seed"
  end
end
