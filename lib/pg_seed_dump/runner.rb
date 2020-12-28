# frozen_string_literal: true
require "table_dumps"
require "table_configuration/full"
require "db/query"
require "file_dump"

module PgSeedDump
  class Runner
    def self.dump!(configuration, file_path)
      new(configuration, file_path).dump!
    end

    def initialize(configuration, file_path)
      @configuration = configuration
      @file_path = file_path
      @table_dumps = TableDumps.new(configuration.table_configurations)
    end

    def dump!
      # TODO: Validate configuration

      # add_schema_migrations_table_to_configuration
      prepare_seed_tables
      dump_tables
      dump_full_tables
      dump_to_file
    end

    private

    attr_reader :configuration, :file_path, :table_dumps

    def add_schema_migrations_table_to_configuration
      return if configuration.configured_tables.include?(:schema_migrations)

      configuration.full(:schema_migrations)
    end

    def prepare_seed_tables
      configuration.seed_table_configurations.each do |table_configuration|
        next unless table_configuration.query

        query = "SELECT #{table_configuration.primary_key} FROM (#{table_configuration.query}) s"
        ids = DB::Query.new(query).rows.map { |row| row[0].to_i }
        table_dumps.add_seed_records_to_process(table_configuration.table_name, ids)
      end
    end

    def dump_tables
      return if table_dumps.all_processed?

      table_dumps.pending_to_process.each(&:dump_pending_records)

      dump_tables # recursive until there are no more records to load
    end

    def dump_full_tables
      table_dumps.pending_to_full_process.each do |table_dump|
        table_dump.run_full_dump = true
        table_dump.dump_pending_records
      end

      # New records loaded from full tables might have foreign keys
      dump_tables
    end

    def dump_to_file
      FileDump.new(configuration, table_dumps).dump_to(file_path)
    end
  end
end
