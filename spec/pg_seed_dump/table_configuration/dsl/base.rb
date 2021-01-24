RSpec.describe PgSeedDump::TableConfiguration::Dsl::Base do
  let(:from_table) { "blog_posts" }
  let(:table_configuration) do
    instance_double("PgSeedDump::TableConfiguration", table_name: from_table)
  end

  describe "#foreign_key" do
    subject { described_class.new(table_configuration) }

    it "stores a foreign key" do
      expect(table_configuration).to receive(:add_foreign_key) do |foreign_key|
        expect(foreign_key.from_table).to eq :blog_posts
        expect(foreign_key.column_name).to eq :user_id
        expect(foreign_key.to_table).to eq :users
      end

      foreign_key = subject.foreign_key "users", "user_id"
    end

    it "doesn't duplicate already defined foreign keys" do
      subject.foreign_key "users", "user_id"
      expect(subject.foreign_keys.size).to eq 1
      expect { subject.foreign_key("users", "user_id") }.to_not change { subject.foreign_keys.size }
    end
  end

  describe "#polymorphic_foreign_key" do
    subject { described_class.new(schema, "comments") }

    it "raises an error if matchers are empty" do
      expect {
        subject.polymorphic_foreign_key("commentable_id", "commentable_type", {})
      }.to raise_error("Add at least one table to type map in comments.commentable_id")
    end

    it "stores a polymorphic foreign key with a single matcher" do
      foreign_key = subject.polymorphic_foreign_key("commentable_id", "commentable_type", {
        users: 'User'
      }).first
      expect(subject.foreign_keys).to contain_exactly(foreign_key)
      expect(foreign_key.from_table).to eq :comments
      expect(foreign_key.column_name).to eq :commentable_id
      expect(foreign_key.to_table).to eq :users
      expect(foreign_key.type_column).to eq :commentable_type
      expect(foreign_key.type_value).to eq 'User'
    end

    it "stores a polymorphic foreign key with multiple matchers" do
      foreign_keys = subject.polymorphic_foreign_key("commentable_id", "commentable_type", {
        users: 'User',
        blog_posts: 'BlogPost'
      })
      expect(subject.foreign_keys).to contain_exactly(*foreign_keys)

      foreign_key = foreign_keys.first
      expect(foreign_key.from_table).to eq :comments
      expect(foreign_key.column_name).to eq :commentable_id
      expect(foreign_key.to_table).to eq :users
      expect(foreign_key.type_column).to eq :commentable_type
      expect(foreign_key.type_value).to eq 'User'

      foreign_key = foreign_keys.second
      expect(foreign_key.from_table).to eq :comments
      expect(foreign_key.column_name).to eq :commentable_id
      expect(foreign_key.to_table).to eq :blog_posts
      expect(foreign_key.type_column).to eq :commentable_type
      expect(foreign_key.type_value).to eq 'BlogPost'
    end
  end
end
