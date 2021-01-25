# frozen_string_literal: true
require "tempfile"
require "pg_seed_dump/db/query"
require "pg_seed_dump/db/table_columns"

module PgSeedDump
  class TableToSqlCopy
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
      ids = [*ids]
      num_records = 0
      copy_encoder = @columns.copy_encoder
      encoding = ActiveRecord::Base.connection.raw_connection.internal_encoding

      measure = Support::Measure.start
      Log.debug(@table_name.to_s.cyan) { "Start processing" }
      DB::Query.new(query_for(ids), decoder: @columns.copy_decoder).rows.each do |row|
        transform_attributes(row)
        process_foreign_keys(row)

        encoded_row = copy_encoder.encode(row, encoding)
        @tempfile.puts clean_escape_chars(encoded_row)

        num_records += 1
        if @table_configuration.sequence_name
          id = @columns.value_at(row, @table_configuration.primary_key).to_i
          @max_id = [@max_id, id].max
        end
      end

      Log.debug(@table_name.to_s.cyan) { "[#{measure.elapsed}] End processing (#{num_records} records)" }
      @num_records_processed += num_records
      missing_num_records = num_records - ids.size
      if ids.size > 0 && missing_num_records > 0
        Log.warn(@table_name.to_s.cyan) { "#{missing_num_records} could not be found" }
      end
    end

    def process_all_records
      process_records
    end

    def process_associated_records(ids)
      @table_configuration.associated_tables do |associated_table_configuration, foreign_keys|
        next if associated_table_configuration.full? # It will be loaded anyway

        query = query_for_associated(ids, associated_table_configuration, foreign_keys)
        associated_ids = DB::Query.new(query).rows.map { |row| row[0].to_i }
        num = @table_dumps.add_records_to_process(associated_table_configuration.table_name, associated_ids)
        if num > 0
          Log.info(associated_table_configuration.table_name.to_s.cyan) { "Adding #{num} records to process from #{@table_name.to_s.cyan} (assoc)" }
        end
      end
    end

    def write_copy_to_file(file)
      return if num_records_processed == 0

      @tempfile.close(false)
      file.puts "COPY public.#{@table_name} (#{@columns}) FROM stdin;"
      File.foreach(@tempfile.path) do |line|
        file.puts line
      end
      file.puts '\.'
      file.puts "\n"
      file.puts sequence_sync
      @tempfile.unlink
    end

    private

    def query_for(ids)
      <<~SQL
        SELECT #{@columns}
        FROM #{@table_name}
        #{"WHERE #{@table_configuration.primary_key} in (#{ids.join(',')})" if ids.any?}
      SQL
    end

    def query_for_associated(ids, associated_table_configuration, foreign_keys)
      sql_conditions = foreign_keys.map do |foreign_key|
        in_clause = "#{foreign_key.column_name} IN (#{ids.to_a.join(",")})"
        next in_clause unless foreign_key.polymorphic?

        "(#{in_clause} AND #{foreign_key.type_column} = '#{foreign_key.type_value}')"
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
      @table_configuration.foreign_keys.each do |foreign_key|
        foreign_key_value = @columns.value_at(row, foreign_key.column_name)
        next if foreign_key_value.nil?

        if foreign_key.polymorphic?
          type_value = @columns.value_at(row, foreign_key.type_column)
          next if type_value != foreign_key.type_value
        end

        foreign_key_ids[foreign_key.to_table] << foreign_key_value.to_i
      end
      foreign_key_ids.each do |foreign_key_table, ids|
        num = @table_dumps.add_records_to_process(foreign_key_table, ids)
        if num > 0
          Log.debug(foreign_key_table.to_s.cyan) { "Adding #{num} records to process from #{@table_name.to_s.cyan} (fk)" }
        end
      end
    end

    def transform_attributes(row)
      @table_configuration.transforms.each do |transform|
        block_params = transform.column_names.map do |column_name|
          @columns.value_at(row, column_name)
        end
        new_value = transform.call(*block_params)
        @columns.set_value(row, transform.column_name, new_value)
      end
    end

    def sequence_sync
      return unless @table_configuration.sequence_name

      "SELECT pg_catalog.setval('public.#{@table_configuration.sequence_name}', #{@max_id});\n\n"
    end

    def clean_escape_chars(row)
      # TODO: try to work with pg encoders so this is not needed
      row.gsub!("\\\n", "\\n")
      row.gsub!("\\\t", "\\t")
      row
    end
  end
end
