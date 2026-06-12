# frozen_string_literal: true

require 'spec_helper'
require 'git/repository'
require 'git/repository/merging'

# Integration-level coverage for Git::Repository::Merging is provided by
# spec/integration/git/repository/merging_spec.rb.
# The unit specs below cover the facade's own orchestration (argument pre-processing,
# option whitelisting, delegation contracts).

RSpec.describe Git::Repository::Merging do
  let(:execution_context) { instance_double(Git::ExecutionContext::Repository) }
  let(:described_instance) { Git::Repository.new(execution_context: execution_context) }

  # ---------------------------------------------------------------------------
  # #merge
  # ---------------------------------------------------------------------------

  describe '#merge' do
    let(:merge_start_command) { instance_double(Git::Commands::Merge::Start) }

    before do
      allow(Git::Commands::Merge::Start)
        .to receive(:new).with(execution_context).and_return(merge_start_command)
    end

    # --- Single String branch ------------------------------------------------

    context 'with a single String branch name' do
      subject(:result) { described_instance.merge('feature') }

      let(:merge_result) { command_result("Merge made by the 'ort' strategy.\n") }

      it 'delegates to Git::Commands::Merge::Start.new with the execution_context' do
        expect(Git::Commands::Merge::Start).to receive(:new).with(execution_context).and_return(merge_start_command)
        allow(merge_start_command).to receive(:call).and_return(merge_result)
        result
      end

      it 'calls Merge::Start#call with the branch name and no_edit: true' do
        expect(merge_start_command)
          .to receive(:call).with('feature', no_edit: true).and_return(merge_result)
        result
      end

      it 'returns the command stdout as a String' do
        allow(merge_start_command)
          .to receive(:call).with('feature', no_edit: true).and_return(merge_result)
        expect(result).to eq("Merge made by the 'ort' strategy.\n")
      end
    end

    # --- Array of branch names (octopus merge) --------------------------------

    context 'with an Array of branch names' do
      subject(:result) { described_instance.merge(%w[feature-a feature-b]) }

      let(:merge_result) { command_result("Merge made by octopus strategy.\n") }

      it 'splats all branch names as separate positional arguments' do
        expect(merge_start_command)
          .to receive(:call).with('feature-a', 'feature-b', no_edit: true).and_return(merge_result)
        result
      end

      it 'returns the command stdout' do
        allow(merge_start_command)
          .to receive(:call).with('feature-a', 'feature-b', no_edit: true).and_return(merge_result)
        expect(result).to eq("Merge made by octopus strategy.\n")
      end
    end

    # --- Git::Branch coercion -------------------------------------------------

    context 'with a Git::Branch object' do
      subject(:result) { described_instance.merge(branch_obj) }

      let(:branch_obj) { instance_double('Git::Branch', to_s: 'feature') }
      let(:merge_result) { command_result("Already up to date.\n") }

      it 'coerces the branch to a String via #to_s' do
        expect(merge_start_command)
          .to receive(:call).with('feature', no_edit: true).and_return(merge_result)
        result
      end
    end

    # --- Positional message argument ------------------------------------------

    context 'with a positional message argument' do
      subject(:result) { described_instance.merge('feature', 'My merge commit') }

      let(:merge_result) { command_result('') }

      it 'translates the message to the :m keyword option' do
        expect(merge_start_command)
          .to receive(:call).with('feature', no_edit: true, m: 'My merge commit').and_return(merge_result)
        result
      end
    end

    context 'with a nil message argument (explicit nil)' do
      subject(:result) { described_instance.merge('feature', nil) }

      let(:merge_result) { command_result('') }

      it 'does not include :m in the call options' do
        expect(merge_start_command)
          .to receive(:call).with('feature', no_edit: true).and_return(merge_result)
        result
      end
    end

    context 'with no message argument' do
      subject(:result) { described_instance.merge('feature') }

      let(:merge_result) { command_result('') }

      it 'does not include :m in the call options' do
        expect(merge_start_command)
          .to receive(:call).with('feature', no_edit: true).and_return(merge_result)
        result
      end
    end

    # --- opts[:message] translation -------------------------------------------

    context 'with opts[:message] (no positional message)' do
      subject(:result) { described_instance.merge('feature', nil, message: 'via opts') }

      let(:merge_result) { command_result('') }

      it 'translates opts[:message] to :m' do
        expect(merge_start_command)
          .to receive(:call).with('feature', no_edit: true, m: 'via opts').and_return(merge_result)
        result
      end

      it 'does not pass :message in the call options' do
        allow(merge_start_command)
          .to receive(:call) do |*, **kw|
            expect(kw).not_to have_key(:message)
            merge_result
          end
        result
      end

      it 'does not mutate the caller opts hash' do
        caller_opts = { message: 'via opts' }
        allow(merge_start_command).to receive(:call).and_return(merge_result)
        described_instance.merge('feature', nil, caller_opts)
        expect(caller_opts).to eq({ message: 'via opts' })
      end
    end

    # --- Pass-through options -------------------------------------------------

    context 'with no_ff: true' do
      subject(:result) { described_instance.merge('feature', nil, no_ff: true) }

      let(:merge_result) { command_result('') }

      it 'passes no_ff: true through to Merge::Start#call' do
        expect(merge_start_command)
          .to receive(:call).with('feature', no_edit: true, no_ff: true).and_return(merge_result)
        result
      end
    end

    context 'with no_commit: true' do
      subject(:result) { described_instance.merge('feature', nil, no_commit: true) }

      let(:merge_result) { command_result('') }

      it 'passes no_commit: true through to Merge::Start#call' do
        expect(merge_start_command)
          .to receive(:call).with('feature', no_edit: true, no_commit: true).and_return(merge_result)
        result
      end
    end

    # --- Combined message + opts ---------------------------------------------

    context 'with a positional message and no_ff: true' do
      subject(:result) { described_instance.merge('feature', 'merge commit', no_ff: true) }

      let(:merge_result) { command_result('') }

      it 'passes m: and no_ff: through to Merge::Start#call' do
        expect(merge_start_command)
          .to receive(:call).with('feature', no_edit: true, m: 'merge commit', no_ff: true).and_return(merge_result)
        result
      end
    end

    # --- Unknown option guard -------------------------------------------------

    context 'with an unknown option' do
      subject(:result) { described_instance.merge('feature', nil, bogus: true) }

      it 'raises ArgumentError' do
        expect { result }.to raise_error(ArgumentError, /Unknown options: bogus/)
      end

      it 'does not call Merge::Start' do
        expect(merge_start_command).not_to receive(:call)
        begin
          result
        rescue ArgumentError
          # expected
        end
      end
    end
  end

  # ---------------------------------------------------------------------------
  # #merge_base
  # ---------------------------------------------------------------------------

  describe '#merge_base' do
    let(:merge_base_command) { instance_double(Git::Commands::MergeBase) }
    let(:merge_base_result) { command_result("abc123\n") }

    before do
      allow(Git::Commands::MergeBase)
        .to receive(:new).with(execution_context).and_return(merge_base_command)
    end

    # --- Basic two-commit invocation -----------------------------------------

    context 'with two branch names' do
      subject(:result) { described_instance.merge_base('main', 'feature') }

      it 'delegates to Git::Commands::MergeBase.new with the execution_context' do
        expect(Git::Commands::MergeBase).to receive(:new).with(execution_context).and_return(merge_base_command)
        allow(merge_base_command).to receive(:call).and_return(merge_base_result)
        result
      end

      it 'calls MergeBase#call with the two commits and no options' do
        expect(merge_base_command)
          .to receive(:call).with('main', 'feature').and_return(merge_base_result)
        result
      end

      it 'returns the stdout lines as an Array<String>' do
        allow(merge_base_command)
          .to receive(:call).with('main', 'feature').and_return(merge_base_result)
        expect(result).to eq(['abc123'])
      end
    end

    # --- Three commits (octopus merge ancestor search) -----------------------

    context 'with three branch names' do
      subject(:result) { described_instance.merge_base('main', 'branch-a', 'branch-b') }

      it 'passes all three commits to MergeBase#call' do
        expect(merge_base_command)
          .to receive(:call).with('main', 'branch-a', 'branch-b').and_return(merge_base_result)
        result
      end
    end

    # --- Trailing hash extraction ---------------------------------------------

    context 'with a trailing options hash' do
      subject(:result) { described_instance.merge_base('main', 'feature', all: true) }

      let(:merge_base_result) { command_result("abc123\ndef456\n") }

      it 'extracts the trailing hash as keyword options' do
        expect(merge_base_command)
          .to receive(:call).with('main', 'feature', all: true).and_return(merge_base_result)
        result
      end

      it 'returns all SHA lines as an Array<String>' do
        allow(merge_base_command)
          .to receive(:call).with('main', 'feature', all: true).and_return(merge_base_result)
        expect(result).to eq(%w[abc123 def456])
      end
    end

    # --- Return value parsing -------------------------------------------------

    context 'when stdout contains trailing whitespace and blank lines' do
      subject(:result) { described_instance.merge_base('main', 'feature') }

      let(:merge_base_result) { command_result("  abc123  \n\n") }

      it 'strips each line and removes blank lines' do
        allow(merge_base_command)
          .to receive(:call).with('main', 'feature').and_return(merge_base_result)
        expect(result).to eq(['abc123'])
      end
    end

    context 'when stdout is empty (no common ancestor)' do
      subject(:result) { described_instance.merge_base('main', 'feature') }

      let(:merge_base_result) { command_result('') }

      it 'returns an empty Array' do
        allow(merge_base_command)
          .to receive(:call).with('main', 'feature').and_return(merge_base_result)
        expect(result).to eq([])
      end
    end

    # --- Option forwarding ----------------------------------------------------

    context 'with octopus: true' do
      subject(:result) { described_instance.merge_base('main', 'b1', 'b2', octopus: true) }

      it 'forwards octopus: true to MergeBase#call' do
        expect(merge_base_command)
          .to receive(:call).with('main', 'b1', 'b2', octopus: true).and_return(merge_base_result)
        result
      end
    end

    context 'with independent: true' do
      subject(:result) { described_instance.merge_base('sha1', 'main', 'feature', independent: true) }

      it 'forwards independent: true to MergeBase#call' do
        expect(merge_base_command)
          .to receive(:call).with('sha1', 'main', 'feature', independent: true).and_return(merge_base_result)
        result
      end
    end

    context 'with fork_point: true' do
      subject(:result) { described_instance.merge_base('main', 'feature', fork_point: true) }

      it 'forwards fork_point: true to MergeBase#call' do
        expect(merge_base_command)
          .to receive(:call).with('main', 'feature', fork_point: true).and_return(merge_base_result)
        result
      end
    end

    # --- Option whitelisting --------------------------------------------------

    context 'option whitelisting' do
      it 'raises ArgumentError for an unknown option key' do
        expect { described_instance.merge_base('main', 'feature', bogus: true) }
          .to raise_error(ArgumentError, /Unknown options: bogus/)
      end

      it 'does not call MergeBase when an unknown option is given' do
        expect(merge_base_command).not_to receive(:call)
        begin
          described_instance.merge_base('main', 'feature', bogus: true)
        rescue ArgumentError
          # expected
        end
      end
    end
  end

  # ---------------------------------------------------------------------------
  # #unmerged
  # ---------------------------------------------------------------------------

  describe '#unmerged' do
    let(:diff_command) { instance_double(Git::Commands::Diff) }

    before do
      allow(Git::Commands::Diff).to receive(:new).with(execution_context).and_return(diff_command)
    end

    context 'when there are no conflicts' do
      before do
        allow(diff_command).to receive(:call).with(cached: true).and_return(command_result(''))
      end

      it 'returns an empty Array' do
        expect(described_instance.unmerged).to eq([])
      end
    end

    context 'when there are conflicts' do
      let(:diff_stdout) { "* Unmerged path file.rb\n* Unmerged path other.rb\n" }

      before do
        allow(diff_command).to receive(:call).with(cached: true).and_return(command_result(diff_stdout))
      end

      it 'returns an Array of the conflicting file paths' do
        expect(described_instance.unmerged).to eq(%w[file.rb other.rb])
      end
    end

    it 'delegates to Git::Commands::Diff.new with the execution_context' do
      allow(diff_command).to receive(:call).with(cached: true).and_return(command_result(''))
      expect(Git::Commands::Diff).to receive(:new).with(execution_context).and_return(diff_command)
      described_instance.unmerged
    end
  end

  # ---------------------------------------------------------------------------
  # #each_conflict
  # ---------------------------------------------------------------------------

  describe '#each_conflict' do
    let(:diff_command) { instance_double(Git::Commands::Diff) }
    let(:show_command) { instance_double(Git::Commands::Show) }
    let(:show_result) { instance_double(Git::CommandLineResult) }

    before do
      allow(Git::Commands::Diff).to receive(:new).with(execution_context).and_return(diff_command)
      allow(Git::Commands::Show).to receive(:new).with(execution_context).and_return(show_command)
      allow(show_command).to receive(:call).and_return(show_result)
    end

    # --- No conflicts ---------------------------------------------------------

    context 'when there are no unmerged files' do
      before do
        allow(diff_command).to receive(:call).with(cached: true).and_return(command_result(''))
      end

      it 'does not yield' do
        expect { |b| described_instance.each_conflict(&b) }.not_to yield_control
      end

      it 'returns an empty Array' do
        expect(described_instance.each_conflict { nil }).to eq([])
      end
    end

    # --- One unmerged file ----------------------------------------------------

    context 'when there is one unmerged file' do
      let(:diff_stdout) { "* Unmerged path example.txt\n" }

      before do
        allow(diff_command)
          .to receive(:call).with(cached: true).and_return(command_result(diff_stdout))
      end

      it 'delegates to Git::Commands::Diff.new with execution_context' do
        expect(Git::Commands::Diff).to receive(:new).with(execution_context).and_return(diff_command)
        described_instance.each_conflict { nil }
      end

      it 'calls Diff#call with cached: true' do
        expect(diff_command).to receive(:call).with(cached: true).and_return(command_result(diff_stdout))
        described_instance.each_conflict { nil }
      end

      it 'yields once' do
        expect { |b| described_instance.each_conflict(&b) }.to yield_control.once
      end

      it 'yields the file path as the first argument' do
        described_instance.each_conflict do |file, _your, _their|
          expect(file).to eq('example.txt')
        end
      end

      it 'yields a String path for your_version' do
        described_instance.each_conflict do |_file, your, _their|
          expect(your).to be_a(String)
        end
      end

      it 'yields a String path for their_version' do
        described_instance.each_conflict do |_file, _your, their|
          expect(their).to be_a(String)
        end
      end

      it 'calls Show with the stage-2 reference' do
        expect(show_command).to receive(:call).with(':2:example.txt', out: anything)
        expect(show_command).to receive(:call).with(':3:example.txt', out: anything)
        described_instance.each_conflict { nil }
      end

      it 'delegates Show.new with the execution_context' do
        expect(Git::Commands::Show).to receive(:new).with(execution_context).and_return(show_command).twice
        described_instance.each_conflict { nil }
      end

      it 'returns an Array containing the unmerged file path' do
        result = described_instance.each_conflict { nil }
        expect(result).to eq(['example.txt'])
      end
    end

    # --- Multiple unmerged files ----------------------------------------------

    context 'when there are multiple unmerged files' do
      let(:diff_stdout) { "* Unmerged path file1.txt\n* Unmerged path file2.txt\n" }

      before do
        allow(diff_command)
          .to receive(:call).with(cached: true).and_return(command_result(diff_stdout))
      end

      it 'yields once per unmerged file' do
        expect { |b| described_instance.each_conflict(&b) }.to yield_control.twice
      end

      it 'yields file paths in order' do
        yielded_files = []
        described_instance.each_conflict { |file, _y, _t| yielded_files << file }
        expect(yielded_files).to eq(%w[file1.txt file2.txt])
      end

      it 'returns an Array of all unmerged file paths' do
        result = described_instance.each_conflict { nil }
        expect(result).to eq(%w[file1.txt file2.txt])
      end
    end

    # --- Output format of diff lines ------------------------------------------

    context 'when the diff output contains non-unmerged lines' do
      let(:diff_stdout) do
        "diff --cc example.txt\nindex abc123..def456\n* Unmerged path example.txt\n--- a/example.txt\n"
      end

      before do
        allow(diff_command)
          .to receive(:call).with(cached: true).and_return(command_result(diff_stdout))
      end

      it 'yields only for lines matching the unmerged path pattern' do
        expect { |b| described_instance.each_conflict(&b) }.to yield_control.once
      end
    end
  end

  # ---------------------------------------------------------------------------
  # #revert
  # ---------------------------------------------------------------------------

  describe '#revert' do
    let(:revert_start_command) { instance_double(Git::Commands::Revert::Start) }

    before do
      allow(Git::Commands::Revert::Start)
        .to receive(:new).with(execution_context).and_return(revert_start_command)
    end

    # --- Default invocation ---------------------------------------------------

    context 'with a commit SHA' do
      subject(:result) { described_instance.revert('abc1234') }

      let(:revert_result) { command_result("[main 1234abc] Revert \"first commit\"\n") }

      it 'delegates to Git::Commands::Revert::Start.new with the execution_context' do
        expect(Git::Commands::Revert::Start).to receive(:new).with(execution_context).and_return(revert_start_command)
        allow(revert_start_command).to receive(:call).and_return(revert_result)
        result
      end

      it 'calls Revert::Start#call with the commit and no_edit: true' do
        expect(revert_start_command)
          .to receive(:call).with('abc1234', no_edit: true).and_return(revert_result)
        result
      end

      it 'returns the command stdout as a String' do
        allow(revert_start_command)
          .to receive(:call).with('abc1234', no_edit: true).and_return(revert_result)
        expect(result).to eq("[main 1234abc] Revert \"first commit\"\n")
      end
    end

    # --- nil commitish defaults to HEAD ---------------------------------------

    context 'with a nil commitish' do
      subject(:result) { described_instance.revert(nil) }

      let(:revert_result) { command_result('') }

      it 'maps nil to HEAD and calls Revert::Start#call with HEAD' do
        expect(revert_start_command)
          .to receive(:call).with('HEAD', no_edit: true).and_return(revert_result)
        result
      end
    end

    # --- no_edit default can be overridden -----------------------------------

    context 'with no_edit: false' do
      subject(:result) { described_instance.revert('abc1234', no_edit: false) }

      let(:revert_result) { command_result('') }

      it 'passes no_edit: false through to Revert::Start#call, overriding the default' do
        expect(revert_start_command)
          .to receive(:call).with('abc1234', no_edit: false).and_return(revert_result)
        result
      end
    end

    # --- no_edit: true explicit (same as default) ----------------------------

    context 'with no_edit: true explicitly' do
      subject(:result) { described_instance.revert('abc1234', no_edit: true) }

      let(:revert_result) { command_result('') }

      it 'passes no_edit: true to Revert::Start#call' do
        expect(revert_start_command)
          .to receive(:call).with('abc1234', no_edit: true).and_return(revert_result)
        result
      end
    end

    # --- Option whitelisting --------------------------------------------------

    context 'option whitelisting' do
      it 'raises ArgumentError for an unknown option key' do
        expect { described_instance.revert('abc1234', bogus: true) }
          .to raise_error(ArgumentError, /Unknown options: bogus/)
      end

      it 'does not call Revert::Start when an unknown option is given' do
        expect(revert_start_command).not_to receive(:call)
        begin
          described_instance.revert('abc1234', bogus: true)
        rescue ArgumentError
          # expected
        end
      end
    end
  end
end
