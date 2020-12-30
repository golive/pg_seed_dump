# frozen_string_literal: true
require "pg_seed_dump/table_dumps"
require "pg_seed_dump/table_configuration/full"
require "pg_seed_dump/db/query"
require "pg_seed_dump/file_dump"
require "pg_seed_dump/support/measure"

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
      Log.info "Starting dump..."
      # TODO: Validate configuration

      measure = Support::Measure.start
      ActiveRecord::Base.transaction do
        prepare_seed_tables
        dump_tables
        dump_full_tables
      end
      dump_to_file
      Log.info "Done in #{measure.elapsed}"
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
      Log.info "Dumping to file #{file_path}"
      FileDump.new(configuration, table_dumps).dump_to(file_path)
    end
  end
end
