# frozen_string_literal: true

module PgSeedDump
  class FileDump
    def initialize(configuration, table_dumps)
      @configuration = configuration
      @table_dumps = table_dumps
    end

    def dump_to(file_path)
      File.open(file_path, "wb") do |file|
        # file.sync = true

        write_pre_data(file)
        write_data(file)
        write_post_data(file)
      end
    end

    private

    attr_reader :configuration, :table_dumps

    def run_pg_dump(section)
      IO.popen("pg_dump #{pg_dump_params} --format=plain --section=#{section}").read
    end

    def write_pre_data(file)
      file.write(run_pg_dump("pre-data"))
    end

    def write_data(file)
      table_dumps.dump_all_processed_to_file(file)
      # TODO: write sequence sync. Ex: SELECT pg_catalog.setval('public.users_id_seq', 1);
    end

    def write_post_data(file)
      file.write(run_pg_dump("post-data"))
    end

    def pg_dump_params
      return @pg_dump_params if defined?(@pg_dump_params)

      params = []
      config = ActiveRecord::Base.connection_db_config.configuration_hash
      params << "-d #{config[:database]}"
      configuration.configured_tables.each do |table_name|
        params << "-t #{table_name}"
      end
      params << "-U #{config[:username]}" if config[:username]
      params << "-h #{config[:host]}" if config[:host]
      params << "-w #{config[:password]}" if config[:password]
      params << "-p #{config[:port]}" if config[:port]

      @pg_dump_params = params.join(" ")
    end
  end
end