# frozen_string_literal: true
require "pg_seed_dump/table_dump/full"
require "pg_seed_dump/table_dump/seed"
require "pg_seed_dump/table_dump/base"

module PgSeedDump
  module TableDump
    def self.new(table_configuration, table_dumps)
      table_dump_class =
        if table_configuration.full?
          TableDump::Full
        elsif table_configuration.seed?
          TableDump::Seed
        else
          TableDump::Base
        end

      table_dump_class.new(table_configuration, table_dumps)
    end
  end
end