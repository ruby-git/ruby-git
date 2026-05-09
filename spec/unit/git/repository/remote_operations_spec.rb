# frozen_string_literal: true

require 'spec_helper'
require 'git/repository'
require 'git/repository/remote_operations'

# Integration-level coverage for Git::Repository::RemoteOperations is provided by
# spec/integration/git/repository/remote_operations_spec.rb.
# The unit specs below cover the facade's own orchestration (argument pre-processing,
# option whitelisting, delegation contracts).

RSpec.describe Git::Repository::RemoteOperations do
  let(:execution_context) { instance_double(Git::ExecutionContext::Repository) }
  let(:described_instance) { Git::Repository.new(execution_context: execution_context) }

  # ---------------------------------------------------------------------------
  # #fetch
  # ---------------------------------------------------------------------------

  describe '#fetch' do
    let(:fetch_command) { instance_double(Git::Commands::Fetch) }
    let(:fetch_result) { command_result('') }

    before do
      allow(Git::Commands::Fetch)
        .to receive(:new).with(execution_context).and_return(fetch_command)
    end

    # --- Default invocation --------------------------------------------------

    context 'with default arguments' do
      subject(:result) { described_instance.fetch }

      it 'delegates to Git::Commands::Fetch.new with the execution_context' do
        expect(Git::Commands::Fetch).to receive(:new).with(execution_context).and_return(fetch_command)
        allow(fetch_command).to receive(:call).and_return(fetch_result)
        result
      end

      it 'calls Fetch#call with the default remote and merge: true' do
        expect(fetch_command)
          .to receive(:call).with('origin', merge: true).and_return(fetch_result)
        result
      end

      it 'returns the command stdout as a String' do
        allow(fetch_command).to receive(:call).and_return(command_result("From origin\n"))
        expect(result).to eq("From origin\n")
      end
    end

    # --- Named remote --------------------------------------------------------

    context 'with an explicit remote name' do
      subject(:result) { described_instance.fetch('upstream') }

      it 'passes the remote as the first positional argument' do
        expect(fetch_command)
          .to receive(:call).with('upstream', merge: true).and_return(fetch_result)
        result
      end
    end

    # --- Hash as first argument (opts only, no remote) -----------------------

    context 'when the first argument is a Hash (opts-only form)' do
      subject(:result) { described_instance.fetch(prune: true) }

      it 'treats the Hash as opts and omits the remote positional argument' do
        expect(fetch_command)
          .to receive(:call).with(prune: true, merge: true).and_return(fetch_result)
        result
      end
    end

    # --- :all option (fetch all remotes) -------------------------------------

    context 'with all: true' do
      subject(:result) { described_instance.fetch('origin', all: true) }

      it 'forwards :all to the command' do
        expect(fetch_command)
          .to receive(:call).with('origin', all: true, merge: true).and_return(fetch_result)
        result
      end
    end

    # --- :ref option (positional refspecs) -----------------------------------

    context 'with a single :ref value' do
      subject(:result) { described_instance.fetch('origin', ref: 'refs/heads/main') }

      it 'appends the refspec as a positional argument after the remote' do
        expect(fetch_command)
          .to receive(:call).with('origin', 'refs/heads/main', merge: true).and_return(fetch_result)
        result
      end
    end

    context 'with an Array :ref value' do
      subject(:result) { described_instance.fetch('origin', ref: %w[refs/heads/main refs/heads/develop]) }

      it 'appends each refspec as a separate positional argument' do
        expect(fetch_command)
          .to receive(:call).with('origin', 'refs/heads/main', 'refs/heads/develop', merge: true)
          .and_return(fetch_result)
        result
      end
    end

    # Known bug: when :ref is supplied without an explicit remote, the refspec is
    # promoted to the :repository operand slot, causing git to treat it as a remote
    # name/URL. This will be fixed in issue #1291.
    context 'with :ref and no remote (Hash form)' do
      subject(:result) { described_instance.fetch(ref: 'refs/heads/main') }

      it 'passes the refspec as the repository positional (pre-#1291 behaviour)' do
        expect(fetch_command)
          .to receive(:call).with('refs/heads/main', merge: true).and_return(fetch_result)
        result
      end
    end

    # --- Key normalization ---------------------------------------------------

    context "with the legacy dash-style key :'update-head-ok'" do
      subject(:result) { described_instance.fetch('origin', 'update-head-ok': true) }

      it "normalizes :'update-head-ok' to :update_head_ok" do
        expect(fetch_command)
          .to receive(:call).with('origin', update_head_ok: true, merge: true).and_return(fetch_result)
        result
      end
    end

    context "with the legacy dash-style key :'prune-tags'" do
      subject(:result) { described_instance.fetch('origin', 'prune-tags': true) }

      it "normalizes :'prune-tags' to :prune_tags" do
        expect(fetch_command)
          .to receive(:call).with('origin', prune_tags: true, merge: true).and_return(fetch_result)
        result
      end
    end

    # --- Option whitelisting -------------------------------------------------

    context 'with an unknown option key' do
      it 'raises ArgumentError before calling the command' do
        expect(fetch_command).not_to receive(:call)
        expect { described_instance.fetch('origin', unknown_opt: true) }
          .to raise_error(ArgumentError, /unknown_opt/)
      end
    end

    # --- Short-form aliases --------------------------------------------------

    context 'with the :p alias for :prune' do
      subject(:result) { described_instance.fetch('origin', p: true) }

      it 'passes :p directly to the command (the DSL handles the alias)' do
        expect(fetch_command)
          .to receive(:call).with('origin', p: true, merge: true).and_return(fetch_result)
        result
      end
    end

    context 'with the :t alias for :tags' do
      subject(:result) { described_instance.fetch('origin', t: true) }

      it 'passes :t directly to the command' do
        expect(fetch_command)
          .to receive(:call).with('origin', t: true, merge: true).and_return(fetch_result)
        result
      end
    end

    context 'with the :f alias for :force' do
      subject(:result) { described_instance.fetch('origin', f: true) }

      it 'passes :f directly to the command' do
        expect(fetch_command)
          .to receive(:call).with('origin', f: true, merge: true).and_return(fetch_result)
        result
      end
    end

    context 'with the :u alias for :update_head_ok' do
      subject(:result) { described_instance.fetch('origin', u: true) }

      it 'passes :u directly to the command' do
        expect(fetch_command)
          .to receive(:call).with('origin', u: true, merge: true).and_return(fetch_result)
        result
      end
    end

    context 'with the :P alias for :prune_tags' do
      subject(:result) { described_instance.fetch('origin', P: true) }

      it 'passes :P directly to the command' do
        expect(fetch_command)
          .to receive(:call).with('origin', P: true, merge: true).and_return(fetch_result)
        result
      end
    end

    # --- :depth option -------------------------------------------------------

    context 'with :depth option' do
      subject(:result) { described_instance.fetch('origin', depth: 5) }

      it 'forwards :depth to the command' do
        expect(fetch_command)
          .to receive(:call).with('origin', depth: 5, merge: true).and_return(fetch_result)
        result
      end
    end

    # --- :unshallow option ---------------------------------------------------

    context 'with :unshallow option' do
      subject(:result) { described_instance.fetch('origin', unshallow: true) }

      it 'forwards :unshallow to the command' do
        expect(fetch_command)
          .to receive(:call).with('origin', unshallow: true, merge: true).and_return(fetch_result)
        result
      end
    end

    # --- opts hash mutation guard --------------------------------------------

    context 'when opts contains :ref' do
      it 'does not mutate the caller-provided opts hash' do
        opts = { ref: 'refs/heads/main' }
        allow(fetch_command).to receive(:call).and_return(fetch_result)
        described_instance.fetch('origin', opts)
        expect(opts).to eq(ref: 'refs/heads/main')
      end
    end
  end
end
