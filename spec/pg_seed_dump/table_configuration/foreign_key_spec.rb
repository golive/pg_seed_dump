RSpec.describe PgSeedDump::TableConfiguration::ForeignKey do
  describe ".new" do
    it "works ok with correct data" do
      foreign_key = described_class.new('blog_posts', 'user_id', 'users')
      expect(foreign_key.from_table).to eq :blog_posts
      expect(foreign_key.column_name).to eq :user_id
      expect(foreign_key.to_table).to eq :users
      expect(foreign_key.type_column).to be_nil
      expect(foreign_key.type_value).to be_nil
      expect(foreign_key).to_not be_polymorphic
    end

    it "raises an error if the origin table doesn't exist" do
      expect {
        described_class.new('blog_posts2', 'user_id', 'users')
      }.to raise_error(
        PgSeedDump::Configuration::TableNotExistsError,
        "Table blog_posts2 doesn't exist"
      )
    end

    it "raises an error if the target table doesn't exist" do
      expect {
        described_class.new('blog_posts', 'user_id', 'users2')
      }.to raise_error(
        PgSeedDump::Configuration::TableNotExistsError,
        "Table users2 doesn't exist"
      )
    end

    it "raises an error if origin table doesn't have the column" do
      expect {
        described_class.new('blog_posts', 'user2_id', 'users')
      }.to raise_error(
        PgSeedDump::Configuration::ColumnNotExistsError,
        "Column user2_id in table blog_posts doesn't exist"
      )
    end

    context "polymorphic" do
      it "works ok with correct data" do
        foreign_key = described_class.new('blog_posts', 'user_id', 'users', 'id', 1)
        expect(foreign_key.from_table).to eq :blog_posts
        expect(foreign_key.column_name).to eq :user_id
        expect(foreign_key.to_table).to eq :users
        expect(foreign_key.type_column).to eq :id
        expect(foreign_key.type_value).to eq 1
        expect(foreign_key).to be_polymorphic
      end

      it "raises an error if matcher column doesn't exist" do
        expect {
          described_class.new('blog_posts', 'user_id', 'users', 'user_type', 'User')
        }.to raise_error(
          PgSeedDump::Configuration::ColumnNotExistsError,
          "Column user_type in table blog_posts doesn't exist"
        )
      end

      it "raises an error if column in origin table and multiple matcher columns doesn't exist" do
        expect {
          described_class.new('blog_posts', 'user2_id', 'users', 'user_type', 'User')
        }.to raise_error(
          PgSeedDump::Configuration::ColumnNotExistsError,
          "Columns user2_id, user_type in table blog_posts doesn't exist"
        )
      end
    end
  end

  describe ".eql?" do
    it "returns true if all params matches" do
      first  = described_class.new('blog_posts', 'user_id', 'users', 'id', 1)
      second = described_class.new('blog_posts', 'user_id', 'users', 'id', 1)

      expect(first.eql?(second)).to be true
      expect(second.eql?(first)).to be true
    end

    it "returns false if origin table name doesn't match" do
      first = described_class.new('users', 'parent_id', 'users')
      second = described_class.new('blog_posts', 'user_id', 'users')

      expect(first.eql?(second)).to be false
    end

    it "returns false if column name doesn't match" do
      first = described_class.new('blog_posts', 'title', 'users')
      second = described_class.new('blog_posts', 'user_id', 'users')

      expect(first.eql?(second)).to be false
    end

    it "returns false if target table doesn't match" do
      first = described_class.new('blog_posts', 'user_id', 'users')
      second = described_class.new('blog_posts', 'user_id', 'comments')

      expect(first.eql?(second)).to be false
    end

    it "returns false if matchers doesn't match" do
      a = described_class.new('blog_posts', 'user_id', 'users')
      b = described_class.new('blog_posts', 'user_id', 'users', 'id', 1)
      c = described_class.new('blog_posts', 'user_id', 'users', 'title', 'my title')
      d = described_class.new('blog_posts', 'user_id', 'users', 'title', 2)
      e = described_class.new('blog_posts', 'user_id', 'users', 'id', 'my title')

      [a, b, c, d, e].combination(2).each do |one, other|
        expect(one.eql?(other)).to be false
      end
    end
  end

  describe "#hash" do
    it "returns the same hash when all attributes are the same" do
      first  = described_class.new('blog_posts', 'user_id', 'users', 'id', 1)
      second = described_class.new('blog_posts', 'user_id', 'users', 'id', 1)

      expect(first.hash).to eq second.hash
    end
  end
end