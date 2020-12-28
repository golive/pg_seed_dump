# frozen_string_literal: true
require_relative 'base'

module PgSeedDump
  module TableConfiguration
    class Seed < Base
      def seed?
        true
      end

      def query
        @query = yield if block_given?
        @query
      end
    end
  end
end
