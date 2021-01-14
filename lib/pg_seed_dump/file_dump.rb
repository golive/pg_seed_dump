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

    def run_pg_dump(section)
      IO.popen("pg_dump #{pg_dump_params} --format=plain --section=#{section}").read
    end

    def write_pre_data(file)
      file.write(run_pg_dump("pre-data"))
    end

    def write_data(file)
      @table_dumps.dump_all_processed_to_file(file)
      # TODO: write sequence sync. Ex: SELECT pg_catalog.setval('public.users_id_seq', 1);
    end

    def write_post_data(file)
      file.write(run_pg_dump("post-data"))
    end

    def pg_dump_params
      return @pg_dump_params if defined?(@pg_dump_params)

      params = []
      params << "-d #{db_config[:database]}"
      @configuration.configured_tables.each do |table_name|
        params << "-t #{table_name}"
      end
      params << "-U #{db_config[:username]}" if db_config[:username]
      params << "-h #{db_config[:host]}" if db_config[:host]
      params << "-w #{db_config[:password]}" if db_config[:password]
      params << "-p #{db_config[:port]}" if db_config[:port]

      @pg_dump_params = params.join(" ")
    end

    def db_config
      @db_config ||= begin
        if ActiveRecord::Base.respond_to?(:connection_db_config)
          return ActiveRecord::Base.connection_db_config.configuration_hash
        end

        ActiveRecord::Base.connection_config
      end
    end
  end
end