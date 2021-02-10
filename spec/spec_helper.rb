require "bundler/setup"
require "pg_seed_dump"
require "active_record"
require "timecop"
require "pry"

DATABASE_NAME = "pg_seed_dump_test"

ActiveRecord::Base.establish_connection(
  adapter: "postgresql",
  database: DATABASE_NAME,
  username: "postgres",
  password: ""
)

Timecop.safe_mode = true

require "support/schema"
Schema.load
require "support/models"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.around(:each, :transactional) do |example|
    ActiveRecord::Base.transaction do
      example.run
      raise ActiveRecord::Rollback
    end
  end
end

def with_dump_file_recover(file_path)
  %i(users blog_posts comments sections tags).each do |table_name|
    ActiveRecord::Base.connection.drop_table table_name, force: :cascade
  end
  system "psql -q -d #{DATABASE_NAME} < #{file_path} > /dev/null 2>&1"
  yield
ensure
  Schema.load
end

def share_same_connection!
  allow(PgSeedDump::DB).to receive(:connection).and_return(ActiveRecord::Base.connection)
end
