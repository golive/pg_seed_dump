# frozen_string_literal: true
require "tempfile"
require "pg_seed_dump/db/query"
require "pg_seed_dump/db/table_columns"

module PgSeedDump
  class TableToSqlCopy
    NIL_VALUE = '\N'

    attr_reader :num_records_processed

    def initialize(table_configuration, table_dumps)
      @table_configuration = table_configuration
      @table_name = table_configuration.table_name
      @table_dumps = table_dumps
      @columns = DB::TableColumns.new(@table_name)
      @tempfile = Tempfile.new([@table_name.to_s, '.sql'])
      @num_records_processed = 0
      @max_id = 0
    end

    def process_records(ids = nil)
      num_records = 0
      DB::Query.new(query_for([*ids])).rows.each do |row|
        process_foreign_keys(row)

        # TODO: process transforms

        tempfile.puts row.join("\t")

        id = columns.value_at(row, :id).to_i
        num_records += 1
        @max_id = [@max_id, id].max
      end
      @num_records_processed += num_records
      Log.info(table_name.to_s.cyan) { "Processed #{num_records} record#{"s" if num_records > 1}" }
    end

    def process_all_records
      process_records
    end

    def process_associated_records(ids)
      table_configuration.associated_tables do |associated_table_configuration, foreign_keys|
        next if associated_table_configuration.full? # It will be loaded anyway

        query = query_for_associated(ids, associated_table_configuration, foreign_keys)
        associated_ids = DB::Query.new(query).rows.map { |row| row[0].to_i }
        table_dumps.add_records_to_process(associated_table_configuration.table_name, associated_ids)
      end
    end

    def write_copy_to_file(file)
      return if num_records_processed == 0

      tempfile.close(false)
      file.puts "COPY public.#{table_name} (#{columns}) FROM stdin;"
      File.foreach(tempfile.path) do |line|
        file.puts line
      end
      file.puts '\.'
      file.puts "\n"
      file.puts sequence_sync
      tempfile.unlink
    end

    private

    attr_reader :tempfile, :table_configuration, :table_name, :table_dumps, :columns

    def query_for(ids)
      <<~SQL
        SELECT #{columns}
        FROM #{table_name}
        #{"WHERE #{table_configuration.primary_key} in (#{ids.join(',')})" if ids.any?}
      SQL
    end

    def query_for_associated(ids, associated_table_configuration, foreign_keys)
      sql_conditions = foreign_keys.map do |foreign_key|
        "#{foreign_key.column_name} IN (#{ids.to_a.join(",")})"
      end
      <<~SQL
        SELECT #{associated_table_configuration.primary_key}
        FROM #{associated_table_configuration.table_name}
        WHERE #{sql_conditions.join(" OR ")}
      SQL
    end

    def process_foreign_keys(row)
      # TODO: warn if some polymorphic foreign key didn't match any value
      foreign_key_ids = Hash.new { |h,k| h[k] = [] }
      table_configuration.foreign_keys.each do |foreign_key|
        foreign_key_value = columns.value_at(row, foreign_key.column_name)
        next if foreign_key_value == NIL_VALUE

        if foreign_key.polymorphic?
          type_value = columns.value_at(row, foreign_key.type_column)
          next if type_value != foreign_key.type_value
        end

        foreign_key_ids[foreign_key.to_table] << foreign_key_value.to_i
      end
      foreign_key_ids.each do |foreign_key_table, ids|
        table_dumps.add_records_to_process(foreign_key_table, ids)
      end
    end

    def sequence_sync
      return unless table_configuration.sequence_name

      "SELECT pg_catalog.setval('public.#{table_configuration.sequence_name}', #{@max_id});\n\n"
    end
  end
end
