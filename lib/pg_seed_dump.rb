# frozen_string_literal: true
require "active_record"
require "pg_seed_dump/version"
require "pg_seed_dump/schema"
require "pg_seed_dump/runner"
require "pg_seed_dump/log"
require "pg_seed_dump/schema/dsl"

module PgSeedDump
  def self.configure
    yield Schema::Dsl.new(schema)
  end

  def self.schema
    @schema ||= Schema.new
  end

  def self.dump(file_path:, log_file_path: nil, debug: false, validate: true)
    Log.setup(log_file_path, debug: debug) if log_file_path
    if validate
      Log.info "Validating the schema..."
      Schema::Validator.new(@schema).validate!
    end
    Runner.dump!(schema, file_path)
  end
end
