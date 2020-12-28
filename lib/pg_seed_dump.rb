# frozen_string_literal: true
require "pg_seed_dump/version"
require "pg_seed_dump/configuration"
require "pg_seed_dump/runner"

module PgSeedDump
  def self.configure
    yield configuration
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.dump(file_path)
    Runner.dump!(configuration, file_path)
  end
end
