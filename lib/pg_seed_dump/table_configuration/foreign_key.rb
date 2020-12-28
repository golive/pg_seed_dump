# frozen_string_literal: true

module PgSeedDump
  module TableConfiguration
    class ForeignKey
      ATTRIBUTES = %i(from_table to_table column_name type_column type_value).freeze
      attr_reader *ATTRIBUTES

      def initialize(from_table, column_name, to_table, type_column = nil, type_value = nil)
        check_tables_exist!([from_table, to_table])
        check_columns_exist!([column_name, type_column].compact, from_table)
        if type_column.nil? ^ type_value.nil?
          raise "Missconfiguration of polymorphic foreign key " \
                "#{from_table}.#{column_name} => #{to_table}"
        end

        @from_table = from_table.to_sym
        @to_table = to_table.to_sym
        @column_name = column_name.to_sym
        @type_column = type_column.to_sym if type_column
        @type_value = type_value
      end

      def eql?(other)
        ATTRIBUTES.all? do |attr|
          send(attr).eql?(other.send(attr))
        end
      end

      def hash
        ATTRIBUTES.sum { |attr| send(attr).hash }
      end

      def polymorphic?
        !@type_column.nil?
      end

      private

      def check_tables_exist!(table_names)
        table_names.each do |table_name|
          unless ActiveRecord::Base.connection.table_exists?(table_name)
            raise Configuration::TableNotExistsError, "Table #{table_name} doesn't exist"
          end
        end
      end

      def check_columns_exist!(column_names, table_name)
        missing_column_names = column_names.reject do |column_name|
          ActiveRecord::Base.connection.column_exists?(table_name, column_name)
        end
        return if missing_column_names.empty?

        raise Configuration::ColumnNotExistsError,
              "Column#{"s" if missing_column_names.size > 1} " \
              "#{missing_column_names.join(', ')} in table #{table_name} doesn't exist"
      end
    end
  end
end