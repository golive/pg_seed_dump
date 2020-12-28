# frozen_string_literal: true
require_relative 'base'

module PgSeedDump
  module TableConfiguration
    class Partial < Base
      def partial?
        true
      end
    end
  end
end
