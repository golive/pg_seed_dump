# frozen_string_literal: true
require "pg_seed_dump/table_dump"

module PgSeedDump
  class TableDumps

    def initialize(table_configurations)
      @table_dumps = table_configurations.each_with_object({}) do |table_configuration, memo|
        memo[table_configuration.table_name] = TableDump.new(table_configuration, self)
      end
    end

    def processed
      @table_dumps.values.reject(&:pending_to_process_records?)
    end

    def pending_to_process
      # TODO: more intelligent ordering
      @table_dumps.values.select(&:pending_to_process_records?)
    end

    def pending_to_full_process
      @table_dumps.values.select { |table_dump| table_dump.table_configuration.full? }
    end

    def all_processed?
      pending_to_process.empty?
    end

    def add_records_to_process(table_name, ids)
      @table_dumps[table_name].add_records_to_process(ids)
    end

    def add_seed_records_to_process(table_name, ids)
      @table_dumps[table_name].add_seed_records_to_process(ids)
    end

    def dump_all_processed_to_file(file)
      @table_dumps.each_value { |table_dump| table_dump.dump_processed_to_file(file) }
    end
  end
end
