require "tempfile"

RSpec.describe PgSeedDump::TableToSqlCopy, :transactional do
  let(:foreign_keys) { [] }
  let(:blog_posts_table_configuration) do
    instance_double(
      "PgSeedDump::TableConfiguration::Partial",
      table_name: :blog_posts,
      foreign_keys: foreign_keys,
      primary_key: :id,
      sequence_name: "blog_posts_id_seq",
      full?: false
    )
  end
  let(:users_table_configuration) do
    instance_double(
      "PgSeedDump::TableConfiguration::Partial",
      table_name: :users,
      foreign_keys: [],
      primary_key: :id,
      sequence_name: "blog_posts_id_seq"
    )
  end

  let(:table_dumps) { spy("PgSeedDump::TableDumps") }
  let(:time) { Time.utc(2020, 12, 28, 0, 0, 0) }
  let(:db_time) { time.strftime("%Y-%m-%d %H:%M:%S") }

  subject { described_class.new(blog_posts_table_configuration, table_dumps) }

  before do
    Timecop.freeze(time) do
      (1..3).each { |id| User.create(id: id) }
      Section.create(id: 1)
      BlogPost.create(
        id: 1,
        title: "My first\tblog post",
        content: "A lot of content",
        user_id: 1,
        section_id: 1
      )
      BlogPost.create(
        id: 2,
        title: "My second\nblog post",
        content: "Amazing stuff",
        user_id: 2,
        section_id: 1
      )
      BlogPost.create(
        id: 3,
        title: "My last blog post",
        content: "Not so inspired this time",
        user_id: 2,
        section_id: nil
      )
      BlogPost.create(id: 4, user_id: 3)
    end
  end

  describe "#process_records" do
    context "without foreign keys" do
      let(:foreign_keys) { [] }

      it "registers processed records" do
        subject.process_records([1, 2])
        expect(subject.num_records_processed).to eq 2
      end

      it "skips not existing records" do
        subject.process_records([1, 100])
        expect(subject.num_records_processed).to eq 1
      end

      it "processes all table records if no ids are provided" do
        subject.process_records
        expect(subject.num_records_processed).to eq BlogPost.count
      end

      it "doesn't process any foreign key" do
        subject.process_records([1])
        expect(table_dumps).to_not have_received(:add_records_to_process)
      end
    end

    context "with foreign keys" do
      let(:foreign_keys) do
        [
          PgSeedDump::TableConfiguration::ForeignKey.new(:blog_posts, :user_id, :users),
          PgSeedDump::TableConfiguration::ForeignKey.new(:blog_posts, :section_id, :sections)
        ]
      end

      it "processes foreign keys with no nils" do
        subject.process_records([1, 2])
        expect(table_dumps).to have_received(:add_records_to_process).with(:users, [1]).ordered
        expect(table_dumps).to have_received(:add_records_to_process).with(:users, [2]).ordered
      end

      it "processes foreign keys with no nils" do
        subject.process_records([3])
        expect(table_dumps).to have_received(:add_records_to_process).with(:users, [2])
        expect(table_dumps).to_not have_received(:add_records_to_process).with(:sections, anything)
      end
    end
  end

  describe "#process_associated_records" do
    subject { described_class.new(users_table_configuration, table_dumps) }

    it "process associated user records" do
      foreign_keys = [PgSeedDump::TableConfiguration::ForeignKey.new(:blog_posts, :user_id, :users)]
      expect(users_table_configuration).to(
        receive(:associated_tables).and_yield(blog_posts_table_configuration, foreign_keys)
      )

      subject.process_associated_records([1, 2])
      expect(table_dumps).to have_received(:add_records_to_process).with(:blog_posts, [1, 2, 3])
    end
  end

  describe "#write_copy_to_file" do
    let(:file) { StringIO.new }

    it "does nothing if no records are processed" do
      subject.write_copy_to_file(file)
      file.rewind
      expect(file.read).to be_empty
    end

    it "writes sql copy data to file" do
      subject.process_records([1, 2])
      subject.write_copy_to_file(file)
      file.rewind
      expect(file.read).to eq(
        "COPY public.blog_posts (id, title, content, user_id, section_id, featured, created_at, updated_at) FROM stdin;\n" \
        "1	My first\\tblog post	A lot of content	1	1	f	#{db_time}	#{db_time}\n" \
        "2	My second\\nblog post	Amazing stuff	2	1	f	#{db_time}	#{db_time}\n" \
        "\\.\n\n" \
        "SELECT pg_catalog.setval('public.blog_posts_id_seq', 2);\n\n"
      )
    end
  end

  describe "#num_records_processed" do
    it "returns num records processed" do
      subject.process_records([1, 2])
      expect(subject.num_records_processed).to eq 2
    end

    it "returns num records processed for full dump" do
      subject.process_records
      expect(subject.num_records_processed).to eq BlogPost.count
    end
  end
end
