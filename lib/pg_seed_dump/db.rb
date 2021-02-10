# frozen_string_literal: true

module PgSeedDump
  module DB
    def self.config
      @config ||= begin
        if ActiveRecord::Base.respond_to?(:connection_db_config)
          ActiveRecord::Base.connection_db_config.configuration_hash
        else
          ActiveRecord::Base.connection_config
        end
      end
    end

    def self.internal_encoding
      raw_connection.internal_encoding
    end

    def self.connection
      @connection || ActiveRecord::Base.connection
    end

    def self.raw_connection
      connection.raw_connection
    end

    def self.with_new_connection
      yield if ActiveRecord::Base.connection_pool.size == ActiveRecord::Base.connection_pool.connections.size

      @connection = ActiveRecord::Base.connection_pool.checkout
      begin
        yield
      ensure
        ActiveRecord::Base.connection_pool.checkin(@connection)
        @connection = nil
      end
    end

    def self.transaction(&block)
      connection.transaction(&block)
    end
  end
end
