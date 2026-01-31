# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/stash/show_numstat'

RSpec.describe Git::Commands::Stash::ShowNumstat do
  let(:execution_context) { double('ExecutionContext') }
  let(:command) { described_class.new(execution_context) }

  let(:numstat_output) do
    <<~OUTPUT
      5\t2\tlib/foo.rb
      3\t1\tlib/bar.rb
       2 files changed, 8 insertions(+), 3 deletions(-)
    OUTPUT
  end

  describe '#call' do
    context 'with no arguments (latest stash)' do
      it 'calls git stash show --numstat --shortstat -M' do
        expect(execution_context).to receive(:command)
          .with('stash', 'show', '--numstat', '--shortstat', '-M')
          .and_return(command_result(numstat_output))

        command.call
      end

      it 'returns DiffResult with stats' do
        allow(execution_context).to receive(:command)
          .with('stash', 'show', '--numstat', '--shortstat', '-M')
          .and_return(command_result(numstat_output))

        result = command.call

        expect(result).to be_a(Git::DiffResult)
        expect(result.files_changed).to eq(2)
        expect(result.total_insertions).to eq(8)
        expect(result.total_deletions).to eq(3)
        expect(result.files.size).to eq(2)
        expect(result.dirstat).to be_nil
      end

      it 'includes per-file stats as DiffFileNumstatInfo objects' do
        allow(execution_context).to receive(:command)
          .with('stash', 'show', '--numstat', '--shortstat', '-M')
          .and_return(command_result(numstat_output))

        result = command.call

        expect(result.files.size).to eq(2)
        expect(result.files[0]).to be_a(Git::DiffFileNumstatInfo)
        expect(result.files[0].path).to eq('lib/foo.rb')
        expect(result.files[0].src_path).to be_nil
        expect(result.files[0].renamed?).to be false
        expect(result.files[0].insertions).to eq(5)
        expect(result.files[0].deletions).to eq(2)
      end
    end

    context 'with specific stash reference' do
      it 'passes stash reference to command' do
        expect(execution_context).to receive(:command)
          .with('stash', 'show', '--numstat', '--shortstat', '-M', 'stash@{2}')
          .and_return(command_result(numstat_output))

        command.call('stash@{2}')
      end
    end

    context 'with :include_untracked option' do
      it 'adds --include-untracked flag when true' do
        expect(execution_context).to receive(:command)
          .with('stash', 'show', '--numstat', '--shortstat', '-M', '--include-untracked')
          .and_return(command_result(numstat_output))

        command.call(include_untracked: true)
      end

      it 'adds --no-include-untracked flag when false' do
        expect(execution_context).to receive(:command)
          .with('stash', 'show', '--numstat', '--shortstat', '-M', '--no-include-untracked')
          .and_return(command_result(numstat_output))

        command.call(include_untracked: false)
      end

      it 'accepts :u alias' do
        expect(execution_context).to receive(:command)
          .with('stash', 'show', '--numstat', '--shortstat', '-M', '--include-untracked')
          .and_return(command_result(numstat_output))

        command.call(u: true)
      end
    end

    context 'with :only_untracked option' do
      it 'adds --only-untracked flag' do
        expect(execution_context).to receive(:command)
          .with('stash', 'show', '--numstat', '--shortstat', '-M', '--only-untracked')
          .and_return(command_result(numstat_output))

        command.call(only_untracked: true)
      end
    end

    context 'with empty stash diff' do
      it 'returns DiffResult with zero stats' do
        allow(execution_context).to receive(:command)
          .with('stash', 'show', '--numstat', '--shortstat', '-M')
          .and_return(command_result(''))

        result = command.call

        expect(result.files_changed).to eq(0)
        expect(result.total_insertions).to eq(0)
        expect(result.total_deletions).to eq(0)
        expect(result.files).to be_empty
      end
    end

    context 'with binary files' do
      let(:binary_numstat) do
        <<~OUTPUT
          -\t-\timage.png
           1 file changed, 0 insertions(+), 0 deletions(-)
        OUTPUT
      end

      it 'handles binary file stats (shown as -)' do
        allow(execution_context).to receive(:command)
          .with('stash', 'show', '--numstat', '--shortstat', '-M')
          .and_return(command_result(binary_numstat))

        result = command.call

        expect(result.files[0].path).to eq('image.png')
        expect(result.files[0].insertions).to eq(0)
        expect(result.files[0].deletions).to eq(0)
      end
    end

    context 'with quoted paths containing special characters' do
      let(:quoted_numstat) do
        <<~OUTPUT
          3\t1\t"lib/path with spaces.rb"
           1 file changed, 3 insertions(+), 1 deletion(-)
        OUTPUT
      end

      it 'unescapes quoted paths' do
        allow(execution_context).to receive(:command)
          .with('stash', 'show', '--numstat', '--shortstat', '-M')
          .and_return(command_result(quoted_numstat))

        result = command.call

        expect(result.files[0].path).to eq('lib/path with spaces.rb')
      end
    end

    context 'with renamed files' do
      let(:simple_rename) do
        <<~OUTPUT
          3\t1\told_name.rb => new_name.rb
           1 file changed, 3 insertions(+), 1 deletion(-)
        OUTPUT
      end
      let(:brace_rename_dir) do
        <<~OUTPUT
          2\t0\t{old_dir => new_dir}/file.rb
           1 file changed, 2 insertions(+)
        OUTPUT
      end
      let(:brace_rename_file) do
        <<~OUTPUT
          5\t2\tlib/{old.rb => new.rb}
           1 file changed, 5 insertions(+), 2 deletions(-)
        OUTPUT
      end

      it 'parses simple rename format' do
        allow(execution_context).to receive(:command)
          .with('stash', 'show', '--numstat', '--shortstat', '-M')
          .and_return(command_result(simple_rename))

        result = command.call

        expect(result.files[0].path).to eq('new_name.rb')
        expect(result.files[0].src_path).to eq('old_name.rb')
        expect(result.files[0].renamed?).to be true
        expect(result.files[0].insertions).to eq(3)
        expect(result.files[0].deletions).to eq(1)
      end

      it 'parses brace rename format for directories' do
        allow(execution_context).to receive(:command)
          .with('stash', 'show', '--numstat', '--shortstat', '-M')
          .and_return(command_result(brace_rename_dir))

        result = command.call

        expect(result.files[0].path).to eq('new_dir/file.rb')
        expect(result.files[0].src_path).to eq('old_dir/file.rb')
        expect(result.files[0].renamed?).to be true
      end

      it 'parses brace rename format for files' do
        allow(execution_context).to receive(:command)
          .with('stash', 'show', '--numstat', '--shortstat', '-M')
          .and_return(command_result(brace_rename_file))

        result = command.call

        expect(result.files[0].path).to eq('lib/new.rb')
        expect(result.files[0].src_path).to eq('lib/old.rb')
        expect(result.files[0].renamed?).to be true
      end
    end

    context 'with :dirstat option' do
      let(:dirstat_output) do
        <<~OUTPUT
          5\t2\tlib/foo.rb
          3\t1\tlib/bar.rb
           2 files changed, 8 insertions(+), 3 deletions(-)
            62.5% lib/
        OUTPUT
      end

      it 'adds --dirstat flag when true' do
        expect(execution_context).to receive(:command)
          .with('stash', 'show', '--numstat', '--shortstat', '-M', '--dirstat')
          .and_return(command_result(dirstat_output))

        command.call(dirstat: true)
      end

      it 'passes dirstat options when string' do
        expect(execution_context).to receive(:command)
          .with('stash', 'show', '--numstat', '--shortstat', '-M', '--dirstat=lines,cumulative')
          .and_return(command_result(dirstat_output))

        command.call(dirstat: 'lines,cumulative')
      end

      it 'parses dirstat output into DirstatInfo' do
        allow(execution_context).to receive(:command)
          .with('stash', 'show', '--numstat', '--shortstat', '-M', '--dirstat')
          .and_return(command_result(dirstat_output))

        result = command.call(dirstat: true)

        expect(result.dirstat).to be_a(Git::DirstatInfo)
        expect(result.dirstat.size).to eq(1)
        expect(result.dirstat['lib/']).to eq(62.5)
        expect(result.dirstat.entries.first.directory).to eq('lib/')
        expect(result.dirstat.entries.first.percentage).to eq(62.5)
      end
    end
  end
end
