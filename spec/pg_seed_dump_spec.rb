require "tempfile"

RSpec.describe PgSeedDump do
  it "has a version number" do
    expect(PgSeedDump::VERSION).not_to be nil
  end

  describe ".configure" do
    it "always yields the same configuration object" do
      PgSeedDump.configure do |config|
        expect(config).to be_an_instance_of(PgSeedDump::Configuration)
        PgSeedDump.configure do |other_config|
          expect(other_config.object_id).to eq config.object_id
        end
      end
    end
  end

  describe ".configuration" do
    it "always returns the same configuration object" do
      config = PgSeedDump.configuration
      expect(config).to be_an_instance_of(PgSeedDump::Configuration)
      expect(config.object_id).to eq PgSeedDump.configuration.object_id
    end
  end

  describe ".dump" do
    let(:time) { Time.utc(2020, 12, 28, 0, 0, 0, 0) }

    before do
      # To avoid sharing the configuration between examples
      allow(PgSeedDump).to receive(:configuration).and_return(PgSeedDump::Configuration.new)
    end

    context "full example" do
      before do
        Timecop.freeze(time) do
          Section.create(id: 1, name: "Section 1")
          Section.create(id: 2, name: "Section 2")
          Section.create(id: 3, name: "Section 3", active: false)

          Tag.create(id: 1, tag: "Tag 1")
          Tag.create(id: 2, tag: "Tag 2")

          # User 100 related data
          User.create(id: 100, name: "Name 1", favourite_section_id: 3)
          BlogPost.create(id: 1, user_id: 100, section_id: 1, title: "My first blog post", content: "content")
          BlogPost.create(id: 2, user_id: 100, section_id: 2, title: "My second blog post", content: "content")
          Comment.create(id: 1, content: "Comment 1", commentable_id: 100, commentable_type: 'User')
          Comment.create(id: 2, content: "Comment 2", commentable_id: 1, commentable_type: 'BlogPost')

          # User 101 related data
          User.create(id: 101, name: "Name 2")
          BlogPost.create(id: 3, user_id: 101, section_id: 1, title: "not imported", content: "content")
          BlogPost.create(id: 4, user_id: 101, section_id: 1, title: "not imported", content: "content")
          Comment.create(id: 3, content: "Comment 1", commentable_id: 101, commentable_type: 'User')
          Comment.create(id: 4, content: "Comment 2", commentable_id: 3, commentable_type: 'BlogPost')
        end

        PgSeedDump.configure do |config|
          config.seed :users do |t|
            t.query { User.where(id: 100).to_sql }
            t.foreign_key :favourite_section_id, :sections
          end

          config.partial :sections

          config.partial :blog_posts do |t|
            t.foreign_key :section_id, :sections, reverse_processing: false
            t.foreign_key :user_id, :users
          end

          config.partial :comments do |t|
            t.polymorphic_foreign_key :commentable_id, :commentable_type, {
              users: 'User',
              blog_posts: 'BlogPost'
            }
          end

          config.full :tags
        end
      end

      it "Dumps and restores tables correctly" do
        file = Tempfile.new(['', '.dump'])
        PgSeedDump.dump(file_path: file.path)
        with_dump_file_recover(file.path) do
          expect(User.count).to eq 1
          user = User.last
          expect(user.id).to eq 100
          expect(user).to have_attributes(
            name: "Name 1", favourite_section_id: 3, created_at: time
          )
          expect(User.create.id).to eq 101

          expect(BlogPost.count).to eq 2
          blog_post = BlogPost.find(2)
          expect(blog_post).to have_attributes(
            user_id: 100, section_id: 2, title: "My second blog post", content: "content"
          )

          expect(Section.count).to eq 3

          expect(Tag.count).to eq 2

          expect(Comment.count).to eq 2
        end
        file.close!
      end
    end

    context "same table associations" do
      context "as seed table" do
        it "protects from loading more records than the ones acting as seed", :transactional do
          PgSeedDump.configure do |config|
            config.seed :users do |t|
              t.query { User.where(id: 1).to_sql }
              t.foreign_key :parent_id, :users
            end
          end

          User.create(id: 1, name: "Name 1", parent_id: nil)
          User.create(id: 2, name: "Name 2", parent_id: 1)

          file = Tempfile.new(['', '.dump'])
          expect { PgSeedDump.dump(file_path: file.path) }.to raise_error "Seed table cannot receive new records to process"
          file.close!
        end
      end

      context "not as seed table" do
        it "loads correctly" do
          PgSeedDump.configure do |config|
            config.seed :blog_posts do |t|
              t.query { BlogPost.where(id: 1).to_sql }
              t.foreign_key :user_id, :users
            end
            config.partial :users do |t|
              t.foreign_key :parent_id, :users
            end
          end

          user = User.create(id: 1, name: "Name 1", parent_id: nil)
          User.create(id: 2, name: "Name 2", parent_id: 1)
          User.create(id: 3, name: "Name 1", parent_id: 2)
          user.update(parent_id: 3) # creating a cycle

          BlogPost.create(id: 1, user_id: 2)

          file = Tempfile.new(['', '.dump'])
          PgSeedDump.dump(file_path: file.path)
          with_dump_file_recover(file.path) do
            expect(User.count).to eq 3
          end
          file.close!
        end
      end
    end
  end
end
