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
end
