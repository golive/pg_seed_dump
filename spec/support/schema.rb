module Schema
  def self.load
    ActiveRecord::Schema.define do
      self.verbose = false

      create_table :blog_posts, force: :cascade do |t|
        t.string :title
        t.string :content
        t.integer :user_id
        t.integer :section_id
        t.boolean :featured, default: false
        t.timestamps
      end

      create_table :users, force: true do |t|
        t.string :name
        t.integer :parent_id
        t.integer :favourite_section_id
        t.timestamps
      end

      create_table :comments, force: true do |t|
        t.string :content
        t.integer :commentable_id
        t.string :commentable_type
        t.timestamps
      end

      create_table :sections, force: true do |t|
        t.string :name
        t.boolean :active, default: true
        t.timestamps
      end

      create_table :tags, force: true do |t|
        t.string :tag
      end

      add_foreign_key :blog_posts, :users
      add_foreign_key :blog_posts, :sections
      add_foreign_key :users, :users, column: :parent_id
      add_foreign_key :users, :sections, column: :favourite_section_id

      add_index :users, :parent_id
    end
  end
end