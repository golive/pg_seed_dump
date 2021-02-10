# frozen_string_literal: true
require "pg_seed_dump/table_dumps"
require "pg_seed_dump/table_configuration/full"
require "pg_seed_dump/db/query"
require "pg_seed_dump/file_dump"
require "pg_seed_dump/support/measure"
require "pg_seed_dump/schema/validator"
require "pg_seed_dump/db"

module PgSeedDump
  class Runner
    def self.dump!(schema, file_path)
      new(schema, file_path).dump!
    end

    def initialize(schema, file_path)
      @schema = schema
      @file_path = file_path
      @table_dumps = TableDumps.new(schema.table_configurations)
    end

    def dump!
      DB.with_new_connection do
        Log.info "Starting dump..."

        measure = Support::Measure.start
        DB.transaction do
          prepare_seed_tables
          dump_tables
          dump_full_tables
        end
        dump_to_file
        Log.info "Done in #{measure.elapsed}"
      end

      log_table_statistics
    end

    private

    def add_schema_migrations_table_to_configuration
      return if @schema.configured_tables.include?(:schema_migrations)

      @schema.full(:schema_migrations)
    end

    def prepare_seed_tables
      @schema.seed_table_configurations.each do |table_configuration|
        Log.debug "Prepare seed #{table_configuration.table_name} table"
        next unless table_configuration.seed_query

        query = "SELECT #{table_configuration.primary_key} FROM (#{table_configuration.seed_query}) s"
        ids = DB::Query.new(query).rows.map { |row| row[0].to_i }
        @table_dumps.add_seed_records_to_process(table_configuration.table_name, ids)
      end
    end

    def dump_tables
      return if @table_dumps.all_processed?
      Log.debug "Dumping tables"

      @table_dumps.pending_to_process.each(&:dump_pending_records)

      dump_tables # recursive until there are no more records to load
    end

    def dump_full_tables
      Log.debug "Dumping full tables"
      @table_dumps.pending_to_full_process.each(&:enable_full_mode)

      # New records loaded from full tables might have foreign keys
      dump_tables
    end

    def dump_to_file
      Log.info "Dumping to file #{@file_path}"
      FileDump.new(@schema, @table_dumps).dump_to(@file_path)
    end

    def log_table_statistics
      Log.info "Dumped records per table:\n"
      statistics = @table_dumps.processed.map do |table_dump|
         [table_dump.num_records_processed, table_dump.table_configuration.table_name]
      end.sort.reverse
      statistics.each do |(num_records, table_name)|
        Log.info "#{num_records.to_s.rjust(9)} #{table_name}"
      end
    end
  end
end
