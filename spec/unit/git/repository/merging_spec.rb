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
end
