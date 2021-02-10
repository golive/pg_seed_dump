# frozen_string_literal: true
require "pg_seed_dump/db"

module PgSeedDump
  class FileDump
    def initialize(schema, table_dumps)
      @schema = schema
      @table_dumps = table_dumps
    end

    def dump_to(file_path)
      File.open(file_path, "wb") do |file|
        write_pre_data(file)
        write_data(file)
        write_post_data(file)
      end
    end

    private

    def run_pg_dump(section)
      IO.popen("pg_dump #{pg_dump_params} --format=plain --section=#{section}").read
    end

    def write_pre_data(file)
      file.write(run_pg_dump("pre-data"))
    end

    def write_data(file)
      @table_dumps.dump_all_processed_to_file(file)
    end

    def write_post_data(file)
      file.write(run_pg_dump("post-data"))
    end

    def pg_dump_params
      return @pg_dump_params if defined?(@pg_dump_params)

      params = []
      params << "-d #{DB.config[:database]}"
      unless @schema.dump_all_db_objects
        @schema.configured_tables.each do |table_name|
          params << "-t #{table_name}"
        end
      end
      params << "-U #{DB.config[:username]}" if DB.config[:username]
      params << "-h #{DB.config[:host]}"     if DB.config[:host]
      params << "-w #{DB.config[:password]}" if DB.config[:password]
      params << "-p #{DB.config[:port]}"     if DB.config[:port]

      @pg_dump_params = params.join(" ")
    end
  end
end
