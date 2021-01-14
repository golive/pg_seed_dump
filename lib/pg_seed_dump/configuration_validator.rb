# frozen_string_literal: true

module PgSeedDump
  class ConfigurationValidator
    def initialize(configuration)
      @configuration = configuration
    end

    def validate!
      validate_seed_tables_with_query
      validate_associations
      check_missing_associations
    end

    private

    def validate_seed_tables_with_query
      return if @configuration.seed_table_configurations.all?(&:query)

      raise StandardError, "Some seed tables doesn't have a query defined"
    end

    def validate_associations
      configured_tables = @configuration.configured_tables
      @configuration.table_configurations.each do |table_configuration|
        table_configuration.foreign_keys.each do |foreign_key|
          next if configured_tables.includes?(foreign_key.to_table)

          raise StandardError,
                "Associated table #{foreign_key.to_table} in " \
                "#{foreign_key.from_table}.#{foreign_key.column_name} doesn't exist"
        end
      end
    end

    def check_missing_associations
      @configuration.table_configurations.each do |table_configuration|
        configured_foreign_keys = table_configuration.foreign_keys.map do |foreign_key|
          next if foreign_key.polymorphic?

          [
            foreign_key.from_table,
            foreign_key.to_table,
            foreign_key.column_name
          ]
        end.compact
        db_foreign_keys = ActiveRecord::Base.connection.foreign_keys(table_name).map do |foreign_key|
          [
            foreign_key.from_table.to_sym,
            foreign_key.to_table.to_sym,
            foreign_key.options[:column].to_sym
          ]
        end

        missing_foreign_keys = db_foreign_keys - configured_foreign_keys

        if missing_foreign_keys.any?
          # TODO: pending
          raise StandardError, "Missing foreign keys"
        end
      end
    end
  end
end