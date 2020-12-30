# frozen_string_literal: true
require "active_record"
require "pg_seed_dump/version"
require "pg_seed_dump/configuration"
require "pg_seed_dump/runner"
require "pg_seed_dump/log"

module PgSeedDump
  def self.configure
    yield configuration
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.dump(file_path:, log_file_path: nil, debug: false)
    Log.setup(log_file_path, debug: debug) if log_file_path
    Runner.dump!(configuration, file_path)
  end
end
