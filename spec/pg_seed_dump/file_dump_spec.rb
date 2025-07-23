# frozen_string_literal: true

require "spec_helper"
require "pg_seed_dump/file_dump"
require "pg_seed_dump/schema"
require "pg_seed_dump/table_dumps"

RSpec.describe PgSeedDump::FileDump do
  let(:schema) { instance_double(PgSeedDump::Schema, dump_all_db_objects: true, configured_tables: []) }
  let(:table_dumps) { instance_double(PgSeedDump::TableDumps) }
  let(:file_dump) { described_class.new(schema, table_dumps) }
  let(:test_file_path) { "/tmp/test_dump.sql" }

  before do
    allow(PgSeedDump::DB).to receive(:config).and_return({
      database: "test_db",
      username: "test_user",
      host: "localhost",
      port: "5432",
      password: "test_password"
    })
    allow(table_dumps).to receive(:dump_all_processed_to_file)
    allow(File).to receive(:open).and_yield(StringIO.new)
  end

  describe "#dump_to" do
    context "when PostgreSQL version is 10 or higher" do
      before do
        allow(Open3).to receive(:capture2).with("pg_dump --version")
          .and_return(["pg_dump (PostgreSQL) 10.0", double(success?: true)])
        allow(Open3).to receive(:capture3).and_return(["", "", double(success?: true)])
      end

      it "calls pg_dump with --no-publications parameter" do
        expect(Open3).to receive(:capture3).with(
          { "PGPASSWORD" => "test_password" },
          a_string_including("--no-publications")
        ).at_least(:once).and_return(["", "", double(success?: true)])

        file_dump.dump_to(test_file_path)
      end
    end

    context "when PostgreSQL version is 9.x" do
      before do
        allow(Open3).to receive(:capture2).with("pg_dump --version")
          .and_return(["pg_dump (PostgreSQL) 9.6", double(success?: true)])
        allow(Open3).to receive(:capture3).and_return(["", "", double(success?: true)])
      end

      it "calls pg_dump without --no-publications parameter" do
        expect(Open3).to receive(:capture3).with(
          { "PGPASSWORD" => "test_password" },
          a_string_not_including("--no-publications")
        ).at_least(:once).and_return(["", "", double(success?: true)])

        file_dump.dump_to(test_file_path)
      end
    end
  end
end
