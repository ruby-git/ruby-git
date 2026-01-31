# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/stash/show_raw'

RSpec.describe Git::Commands::Stash::ShowRaw do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  # Sample combined --raw, --numstat, and --shortstat output with rename detection
  let(:raw_output) do
    <<~OUTPUT
      :100644 100644 abc1234 def5678 M\tlib/foo.rb
      :000000 100644 0000000 1234567 A\tlib/bar.rb
      5\t2\tlib/foo.rb
      10\t0\tlib/bar.rb
       2 files changed, 15 insertions(+), 2 deletions(-)
    OUTPUT
  end

  let(:raw_output_with_rename) do
    <<~OUTPUT
      :100644 100644 abc1234 def5678 R075\told_name.rb\tnew_name.rb
      :000000 100644 0000000 1234567 A\tlib/bar.rb
      3\t1\tnew_name.rb
      10\t0\tlib/bar.rb
       2 files changed, 13 insertions(+), 1 deletion(-)
    OUTPUT
  end

  describe '#call' do
    context 'with no arguments (latest stash)' do
      it 'calls git stash show --raw --numstat --shortstat -M' do
        expect(execution_context).to receive(:command)
          .with('stash', 'show', '--raw', '--numstat', '--shortstat', '-M')
          .and_return(command_result(raw_output))

        command.call
      end

      it 'returns DiffResult' do
        allow(execution_context).to receive(:command)
          .with('stash', 'show', '--raw', '--numstat', '--shortstat', '-M')
          .and_return(command_result(raw_output))

        result = command.call

        expect(result).to be_a(Git::DiffResult)
        expect(result.files.size).to eq(2)
        expect(result.files_changed).to eq(2)
        expect(result.total_insertions).to eq(15)
        expect(result.total_deletions).to eq(2)
        expect(result.dirstat).to be_nil
      end

      it 'parses file status correctly' do
        allow(execution_context).to receive(:command)
          .with('stash', 'show', '--raw', '--numstat', '--shortstat', '-M')
          .and_return(command_result(raw_output))

        result = command.call

        expect(result.files[0]).to be_a(Git::DiffFileRawInfo)
        expect(result.files[0].path).to eq('lib/foo.rb')
        expect(result.files[0].status).to eq(:modified)
        expect(result.files[0].insertions).to eq(5)
        expect(result.files[0].deletions).to eq(2)
        expect(result.files[0].src).to be_a(Git::FileRef)
        expect(result.files[0].src.mode).to eq('100644')
        expect(result.files[0].src.sha).to eq('abc1234')
        expect(result.files[0].src.path).to eq('lib/foo.rb')
        expect(result.files[0].dst).to be_a(Git::FileRef)
        expect(result.files[0].dst.mode).to eq('100644')
        expect(result.files[0].dst.sha).to eq('def5678')
        expect(result.files[0].dst.path).to eq('lib/foo.rb')
        expect(result.files[0].similarity).to be_nil
      end

      it 'parses added files correctly with nil src' do
        allow(execution_context).to receive(:command)
          .with('stash', 'show', '--raw', '--numstat', '--shortstat', '-M')
          .and_return(command_result(raw_output))

        result = command.call

        added_file = result.files.find { |f| f.status == :added }
        expect(added_file.path).to eq('lib/bar.rb')
        expect(added_file.src).to be_nil
        expect(added_file.dst).to be_a(Git::FileRef)
        expect(added_file.dst.sha).to eq('1234567')
        expect(added_file.insertions).to eq(10)
        expect(added_file.deletions).to eq(0)
      end
    end

    context 'with renamed files' do
      it 'parses renames with similarity percentage' do
        allow(execution_context).to receive(:command)
          .with('stash', 'show', '--raw', '--numstat', '--shortstat', '-M')
          .and_return(command_result(raw_output_with_rename))

        result = command.call

        renamed = result.files.find { |f| f.status == :renamed }
        expect(renamed.path).to eq('new_name.rb')
        expect(renamed.src_path).to eq('old_name.rb')
        expect(renamed.similarity).to eq(75)
        expect(renamed.insertions).to eq(3)
        expect(renamed.deletions).to eq(1)
      end
    end

    context 'with specific stash reference' do
      it 'passes stash reference to command' do
        expect(execution_context).to receive(:command)
          .with('stash', 'show', '--raw', '--numstat', '--shortstat', '-M', 'stash@{2}')
          .and_return(command_result(raw_output))

        command.call('stash@{2}')
      end
    end

    context 'with :include_untracked option' do
      it 'adds --include-untracked flag when true' do
        expect(execution_context).to receive(:command)
          .with('stash', 'show', '--raw', '--numstat', '--shortstat', '-M', '--include-untracked')
          .and_return(command_result(raw_output))

        command.call(include_untracked: true)
      end

      it 'adds --no-include-untracked flag when false' do
        expect(execution_context).to receive(:command)
          .with('stash', 'show', '--raw', '--numstat', '--shortstat', '-M', '--no-include-untracked')
          .and_return(command_result(raw_output))

        command.call(include_untracked: false)
      end
    end

    context 'with :only_untracked option' do
      it 'adds --only-untracked flag' do
        expect(execution_context).to receive(:command)
          .with('stash', 'show', '--raw', '--numstat', '--shortstat', '-M', '--only-untracked')
          .and_return(command_result(raw_output))

        command.call(only_untracked: true)
      end
    end

    context 'with :find_copies option' do
      it 'adds -C flag when true' do
        expect(execution_context).to receive(:command)
          .with('stash', 'show', '--raw', '--numstat', '--shortstat', '-M', '-C')
          .and_return(command_result(raw_output))

        command.call(find_copies: true)
      end
    end

    context 'with empty stash diff' do
      it 'returns DiffResult with no files' do
        allow(execution_context).to receive(:command)
          .with('stash', 'show', '--raw', '--numstat', '--shortstat', '-M')
          .and_return(command_result(''))

        result = command.call

        expect(result.files).to be_empty
        expect(result.files_changed).to eq(0)
      end
    end

    context 'with all status types' do
      let(:all_statuses_output) do
        <<~OUTPUT
          :100644 100644 abc1234 def5678 M\tmodified.rb
          :000000 100644 0000000 1234567 A\tadded.rb
          :100644 000000 abc1234 0000000 D\tdeleted.rb
          :100644 100644 abc1234 def5678 R090\told.rb\trenamed.rb
          :100644 100644 abc1234 def5678 C080\tsource.rb\tcopied.rb
          :100644 120000 abc1234 def5678 T\ttype_changed.rb
          5\t2\tmodified.rb
          10\t0\tadded.rb
          0\t5\tdeleted.rb
          2\t1\trenamed.rb
          8\t0\tcopied.rb
          0\t0\ttype_changed.rb
           6 files changed, 25 insertions(+), 8 deletions(-)
        OUTPUT
      end

      it 'parses all status types correctly' do
        allow(execution_context).to receive(:command)
          .with('stash', 'show', '--raw', '--numstat', '--shortstat', '-M')
          .and_return(command_result(all_statuses_output))

        result = command.call

        statuses = result.files.map(&:status)
        expect(statuses).to include(:modified, :added, :deleted, :renamed, :copied, :type_changed)
      end

      it 'parses deleted files with src only and nil dst' do
        allow(execution_context).to receive(:command)
          .with('stash', 'show', '--raw', '--numstat', '--shortstat', '-M')
          .and_return(command_result(all_statuses_output))

        result = command.call

        deleted_file = result.files.find { |f| f.status == :deleted }
        expect(deleted_file.path).to eq('deleted.rb')
        expect(deleted_file.src).to be_a(Git::FileRef)
        expect(deleted_file.src.mode).to eq('100644')
        expect(deleted_file.src.sha).to eq('abc1234')
        expect(deleted_file.dst).to be_nil
        expect(deleted_file.deletions).to eq(5)
      end

      it 'parses renamed files with different src and dst paths' do
        allow(execution_context).to receive(:command)
          .with('stash', 'show', '--raw', '--numstat', '--shortstat', '-M')
          .and_return(command_result(all_statuses_output))

        result = command.call

        renamed_file = result.files.find { |f| f.status == :renamed }
        expect(renamed_file.path).to eq('renamed.rb')
        expect(renamed_file.src).to be_a(Git::FileRef)
        expect(renamed_file.src.path).to eq('old.rb')
        expect(renamed_file.dst).to be_a(Git::FileRef)
        expect(renamed_file.dst.path).to eq('renamed.rb')
        expect(renamed_file.similarity).to eq(90)
      end
    end

    context 'with binary files' do
      let(:binary_output) do
        <<~OUTPUT
          :100644 100644 abc1234 def5678 M\timage.png
          -\t-\timage.png
           1 file changed, 0 insertions(+), 0 deletions(-)
        OUTPUT
      end

      it 'detects binary files from numstat output' do
        allow(execution_context).to receive(:command)
          .with('stash', 'show', '--raw', '--numstat', '--shortstat', '-M')
          .and_return(command_result(binary_output))

        result = command.call

        file = result.files.first
        expect(file.path).to eq('image.png')
        expect(file.binary?).to be true
        expect(file.insertions).to eq(0)
        expect(file.deletions).to eq(0)
      end
    end

    context 'result totals from shortstat' do
      it 'gets total_insertions from shortstat' do
        allow(execution_context).to receive(:command)
          .with('stash', 'show', '--raw', '--numstat', '--shortstat', '-M')
          .and_return(command_result(raw_output))

        result = command.call

        expect(result.total_insertions).to eq(15)
      end

      it 'gets total_deletions from shortstat' do
        allow(execution_context).to receive(:command)
          .with('stash', 'show', '--raw', '--numstat', '--shortstat', '-M')
          .and_return(command_result(raw_output))

        result = command.call

        expect(result.total_deletions).to eq(2)
      end
    end

    context 'with :dirstat option' do
      let(:dirstat_output) do
        <<~OUTPUT
          :100644 100644 abc1234 def5678 M\tlib/foo.rb
          :000000 100644 0000000 1234567 A\tlib/bar.rb
          5\t2\tlib/foo.rb
          10\t0\tlib/bar.rb
           2 files changed, 15 insertions(+), 2 deletions(-)
           100.0% lib/
        OUTPUT
      end

      it 'adds --dirstat flag when true' do
        expect(execution_context).to receive(:command)
          .with('stash', 'show', '--raw', '--numstat', '--shortstat', '-M', '--dirstat')
          .and_return(command_result(dirstat_output))

        command.call(dirstat: true)
      end

      it 'passes dirstat options when string' do
        expect(execution_context).to receive(:command)
          .with('stash', 'show', '--raw', '--numstat', '--shortstat', '-M', '--dirstat=files')
          .and_return(command_result(dirstat_output))

        command.call(dirstat: 'files')
      end

      it 'parses dirstat output into DirstatInfo' do
        allow(execution_context).to receive(:command)
          .with('stash', 'show', '--raw', '--numstat', '--shortstat', '-M', '--dirstat')
          .and_return(command_result(dirstat_output))

        result = command.call(dirstat: true)

        expect(result.dirstat).to be_a(Git::DirstatInfo)
        expect(result.dirstat['lib/']).to eq(100.0)
      end
    end
  end
end
