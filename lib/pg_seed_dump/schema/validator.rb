# frozen_string_literal: true

module PgSeedDump
  class Schema
    class Validator
      def initialize(schema)
        @schema = schema
      end

      def validate!(require_all_tables: false)
        validate_all_tables_configured if require_all_tables
        validate_seed_tables_with_query
        validate_associations
        check_missing_associations
      end

      private

      def validate_all_tables_configured
        missing_tables = ActiveRecord::Base.connection.tables.map(&:to_sym) - @schema.configured_tables
        if missing_tables.any?
          raise StandardError, "Missing configuration for #{missing_tables} table#{"s" if missing_tables.many?}"
        end
      end

      def validate_seed_tables_with_query
        seed_tables_without_seed_query = @schema.seed_table_configurations.reject(&:seed_query)
        if seed_tables_without_seed_query.any?
          raise StandardError,
                "Missing seed query for #{seed_table_configurations.map(&:table_name).join(', ')}" \
                "table#{"s" if seed_table_configurations.many?}"
        end
      end

      def validate_associations
        configured_tables = @schema.configured_tables
        @schema.table_configurations.each do |table_configuration|
          table_configuration.foreign_keys.each do |foreign_key|
            next if configured_tables.include?(foreign_key.to_table)

            raise StandardError,
                  "Associated table #{foreign_key.to_table} in " \
                  "#{foreign_key.from_table}.#{foreign_key.column_name} doesn't exist"
          end
        end
      end

      def check_missing_associations
        @schema.table_configurations.each do |table_configuration|
          missing_foreign_keys = db_foreign_keys(table_configuration) - configured_foreign_keys(table_configuration)

          if missing_foreign_keys.any?
            # TODO: pending
            raise StandardError, "Missing foreign keys #{missing_foreign_keys.map(&:last).join(', ')} " \
                                 "for table #{table_configuration.table_name}"
          end
        end
      end

      def configured_foreign_keys(table_configuration)
        table_configuration.foreign_keys.map do |foreign_key|
          next if foreign_key.polymorphic?

          [foreign_key.to_table, foreign_key.column_name]
        end.compact
      end

      def db_foreign_keys(table_configuration)
        ActiveRecord::Base.connection.foreign_keys(table_configuration.table_name).map do |foreign_key|
          to_table = foreign_key.to_table.to_sym
          column_name = foreign_key.options[:column].to_sym

          table_configuration = @schema.configuration_for_table(to_table)
          if table_configuration
            next if table_configuration.full?
            next if table_configuration.transforms.any? { |t| t.column_name == column_name }
          end

          [to_table, column_name]
        end.compact
      end
    end
  end
end