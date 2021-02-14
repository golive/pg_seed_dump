# frozen_string_literal: true
require_relative 'base'

module PgSeedDump
  module TableConfiguration
    class Empty < Base
      def empty?
        true
      end
    end
  end
end
