# frozen_string_literal: true

require 'spec_helper'
require 'git/repository'
require 'git/repository/committing'

# Integration-level coverage for Git::Repository::Committing:
#
# Single-command delegators (#commit, #commit_all, #commit_tree, #write_tree)
# are covered end-to-end by:
#   spec/integration/git/commands/commit_spec.rb
#   spec/integration/git/commands/commit_tree_spec.rb
#   spec/integration/git/commands/write_tree_spec.rb
#
# The multi-command #write_and_commit_tree method is covered by:
#   spec/integration/git/repository/committing_spec.rb
#
# The unit specs below cover the facade's own behavior: option whitelisting,
# argument pre-processing, deprecation handling, and delegation contracts.

RSpec.describe Git::Repository::Committing do
  let(:execution_context) { instance_double(Git::ExecutionContext::Repository) }
  let(:described_instance) { Git::Repository.new(execution_context: execution_context) }

  # ─────────────────────────────────────────────────────────────────────────
  # #commit
  # ─────────────────────────────────────────────────────────────────────────
  describe '#commit' do
    let(:commit_command) { instance_double(Git::Commands::Commit) }
    let(:commit_result) { command_result('') }

    before do
      allow(Git::Commands::Commit).to receive(:new).with(execution_context).and_return(commit_command)
    end

    context 'with a message only' do
      subject(:result) { described_instance.commit('Initial commit') }

      it 'delegates to Git::Commands::Commit#call with no_edit: true and the message' do
        expect(commit_command).to receive(:call).with(no_edit: true,
                                                      message: 'Initial commit').and_return(commit_result)
        result
      end

      it 'returns the command stdout' do
        allow(commit_command).to receive(:call).and_return(command_result('main 1234abc] Initial commit'))
        expect(result).to eq('main 1234abc] Initial commit')
      end
    end

    context 'with message nil' do
      subject(:result) { described_instance.commit(nil) }

      it 'does not include :message in the call' do
        expect(commit_command).to receive(:call).with(no_edit: true).and_return(commit_result)
        result
      end
    end

    context 'with no message argument' do
      subject(:result) { described_instance.commit(amend: true) }

      it 'does not include :message in the call' do
        expect(commit_command).to receive(:call).with(no_edit: true, amend: true).and_return(commit_result)
        result
      end
    end

    context 'with all: true' do
      subject(:result) { described_instance.commit('msg', all: true) }

      it 'forwards all: true to the command' do
        expect(commit_command).to receive(:call).with(no_edit: true, message: 'msg',
                                                      all: true).and_return(commit_result)
        result
      end
    end

    context 'with amend: true' do
      subject(:result) { described_instance.commit('msg', amend: true) }

      it 'forwards amend: true to the command' do
        expect(commit_command).to receive(:call).with(no_edit: true, message: 'msg',
                                                      amend: true).and_return(commit_result)
        result
      end
    end

    context 'with allow_empty: true' do
      subject(:result) { described_instance.commit('msg', allow_empty: true) }

      it 'forwards allow_empty: true to the command' do
        expect(commit_command).to receive(:call).with(no_edit: true, message: 'msg',
                                                      allow_empty: true).and_return(commit_result)
        result
      end
    end

    context 'with allow_empty_message: true' do
      subject(:result) { described_instance.commit('msg', allow_empty_message: true) }

      it 'forwards allow_empty_message: true to the command' do
        expect(commit_command).to receive(:call).with(no_edit: true, message: 'msg',
                                                      allow_empty_message: true).and_return(commit_result)
        result
      end
    end

    context 'with author: option' do
      subject(:result) { described_instance.commit('msg', author: 'Jane <jane@example.com>') }

      it 'forwards author to the command' do
        expect(commit_command).to receive(:call).with(no_edit: true, message: 'msg',
                                                      author: 'Jane <jane@example.com>').and_return(commit_result)
        result
      end
    end

    context 'with date: option' do
      subject(:result) { described_instance.commit('msg', date: '2024-01-01T00:00:00') }

      it 'forwards date to the command' do
        expect(commit_command).to receive(:call).with(no_edit: true, message: 'msg',
                                                      date: '2024-01-01T00:00:00').and_return(commit_result)
        result
      end
    end

    context 'with gpg_sign: true' do
      subject(:result) { described_instance.commit('msg', gpg_sign: true) }

      it 'forwards gpg_sign: true to the command' do
        expect(commit_command).to receive(:call).with(no_edit: true, message: 'msg',
                                                      gpg_sign: true).and_return(commit_result)
        result
      end
    end

    context 'with no_gpg_sign: true' do
      subject(:result) { described_instance.commit('msg', no_gpg_sign: true) }

      it 'forwards no_gpg_sign: true to the command' do
        expect(commit_command).to receive(:call).with(no_edit: true, message: 'msg',
                                                      no_gpg_sign: true).and_return(commit_result)
        result
      end
    end

    context 'with no_verify: true' do
      subject(:result) { described_instance.commit('msg', no_verify: true) }

      it 'forwards no_verify: true to the command' do
        expect(commit_command).to receive(:call).with(no_edit: true, message: 'msg',
                                                      no_verify: true).and_return(commit_result)
        result
      end
    end

    context 'with deprecated :add_all option' do
      subject(:result) { described_instance.commit('msg', add_all: true) }

      it 'emits a deprecation warning' do
        allow(commit_command).to receive(:call).and_return(commit_result)
        expect(Git::Deprecation).to receive(:warn).with(a_string_including(':add_all'))
        result
      end

      it 'converts :add_all to :all and forwards to the command' do
        allow(Git::Deprecation).to receive(:warn)
        expect(commit_command).to receive(:call).with(no_edit: true, message: 'msg',
                                                      all: true).and_return(commit_result)
        result
      end
    end

    context 'with an unknown option' do
      subject(:result) { described_instance.commit('msg', bogus: true) }

      it 'raises ArgumentError' do
        expect { result }.to raise_error(ArgumentError, /Unknown options: bogus/)
      end

      it 'does not call Git::Commands::Commit' do
        expect(commit_command).not_to receive(:call)
        begin
          result
        rescue ArgumentError
          # expected
        end
      end
    end
  end

  # ─────────────────────────────────────────────────────────────────────────
  # #commit_all
  # ─────────────────────────────────────────────────────────────────────────
  describe '#commit_all' do
    let(:commit_command) { instance_double(Git::Commands::Commit) }
    let(:commit_result) { command_result('') }

    before do
      allow(Git::Commands::Commit).to receive(:new).with(execution_context).and_return(commit_command)
    end

    context 'with a message only' do
      subject(:result) { described_instance.commit_all('msg') }

      it 'delegates to the commit command with all: true' do
        expect(commit_command).to receive(:call).with(no_edit: true, message: 'msg',
                                                      all: true).and_return(commit_result)
        result
      end

      it 'returns the command stdout' do
        allow(commit_command).to receive(:call).and_return(command_result('commit output'))
        expect(result).to eq('commit output')
      end
    end

    context 'with additional options' do
      subject(:result) { described_instance.commit_all('msg', no_verify: true) }

      it 'forwards extra options alongside all: true' do
        expect(commit_command).to receive(:call).with(no_edit: true, message: 'msg', all: true,
                                                      no_verify: true).and_return(commit_result)
        result
      end
    end
  end

  # ─────────────────────────────────────────────────────────────────────────
  # #commit_tree
  # ─────────────────────────────────────────────────────────────────────────
  describe '#commit_tree' do
    let(:commit_tree_command) { instance_double(Git::Commands::CommitTree) }
    let(:commit_tree_result) { command_result('abc1234') }

    before do
      allow(Git::Commands::CommitTree).to receive(:new).with(execution_context).and_return(commit_tree_command)
    end

    context 'with a tree and no options' do
      subject(:result) { described_instance.commit_tree('tree-sha') }

      it 'delegates with a default message derived from the tree' do
        expect(commit_tree_command).to(
          receive(:call)
            .with('tree-sha', m: 'commit tree tree-sha')
            .and_return(commit_tree_result)
        )
        result
      end

      it 'returns the SHA string from stdout' do
        allow(commit_tree_command).to receive(:call).and_return(commit_tree_result)
        expect(result).to eq('abc1234')
      end
    end

    context 'with a message option' do
      subject(:result) { described_instance.commit_tree('tree-sha', message: 'my message') }

      it 'normalizes :message to :m before calling the command' do
        expect(commit_tree_command).to receive(:call).with('tree-sha',
                                                           m: 'my message').and_return(commit_tree_result)
        result
      end
    end

    context 'with :m option directly' do
      subject(:result) { described_instance.commit_tree('tree-sha', m: 'my message') }

      it 'passes :m directly to the command' do
        expect(commit_tree_command).to receive(:call).with('tree-sha', m: 'my message').and_return(commit_tree_result)
        result
      end
    end

    context 'with message: nil explicitly' do
      subject(:result) { described_instance.commit_tree('tree-sha', message: nil) }

      it 'falls back to the default message' do
        expect(commit_tree_command).to(
          receive(:call)
            .with('tree-sha', m: 'commit tree tree-sha')
            .and_return(commit_tree_result)
        )
        result
      end
    end

    context 'with m: nil explicitly' do
      subject(:result) { described_instance.commit_tree('tree-sha', m: nil) }

      it 'falls back to the default message' do
        expect(commit_tree_command).to(
          receive(:call)
            .with('tree-sha', m: 'commit tree tree-sha')
            .and_return(commit_tree_result)
        )
        result
      end
    end

    context 'with :parent option' do
      subject(:result) { described_instance.commit_tree('tree-sha', parent: 'parent-sha', message: 'msg') }

      it 'normalizes :parent to :p and :message to :m before calling the command' do
        expect(commit_tree_command).to receive(:call).with('tree-sha', p: 'parent-sha',
                                                                       m: 'msg').and_return(commit_tree_result)
        result
      end
    end

    context 'with :parents option (array)' do
      subject(:result) { described_instance.commit_tree('tree-sha', parents: %w[sha1 sha2], message: 'msg') }

      it 'normalizes :parents to :p and :message to :m before calling the command' do
        expect(commit_tree_command).to receive(:call).with('tree-sha', p: %w[sha1 sha2],
                                                                       m: 'msg').and_return(commit_tree_result)
        result
      end
    end

    context 'with :p option directly' do
      subject(:result) { described_instance.commit_tree('tree-sha', p: 'parent-sha', message: 'msg') }

      it 'normalizes :message to :m and passes :p directly to the command' do
        expect(commit_tree_command).to receive(:call).with('tree-sha', p: 'parent-sha',
                                                                       m: 'msg').and_return(commit_tree_result)
        result
      end
    end

    context 'with an unknown option' do
      subject(:result) { described_instance.commit_tree('tree-sha', bogus: true) }

      it 'raises ArgumentError' do
        expect { result }.to raise_error(ArgumentError, /Unknown options: bogus/)
      end
    end
  end

  # ─────────────────────────────────────────────────────────────────────────
  # #write_tree
  # ─────────────────────────────────────────────────────────────────────────
  describe '#write_tree' do
    let(:write_tree_command) { instance_double(Git::Commands::WriteTree) }
    let(:write_tree_result) { command_result('deadbeef') }

    before do
      allow(Git::Commands::WriteTree).to receive(:new).with(execution_context).and_return(write_tree_command)
    end

    it 'delegates to Git::Commands::WriteTree#call' do
      expect(write_tree_command).to receive(:call).and_return(write_tree_result)
      described_instance.write_tree
    end

    it 'returns the tree SHA from stdout' do
      allow(write_tree_command).to receive(:call).and_return(write_tree_result)
      expect(described_instance.write_tree).to eq('deadbeef')
    end
  end

  # ─────────────────────────────────────────────────────────────────────────
  # #write_and_commit_tree
  # ─────────────────────────────────────────────────────────────────────────
  describe '#write_and_commit_tree' do
    let(:write_tree_command) { instance_double(Git::Commands::WriteTree) }
    let(:commit_tree_command) { instance_double(Git::Commands::CommitTree) }
    let(:tree_sha) { 'deadbeef' }
    let(:commit_sha) { 'cafebabe' }

    before do
      allow(Git::Commands::WriteTree).to receive(:new).with(execution_context).and_return(write_tree_command)
      allow(Git::Commands::CommitTree).to receive(:new).with(execution_context).and_return(commit_tree_command)
    end

    context 'with no options' do
      subject(:result) { described_instance.write_and_commit_tree }

      it 'calls write_tree then commit_tree in order' do
        expect(write_tree_command).to(
          receive(:call)
            .and_return(command_result(tree_sha))
            .ordered
        )
        expect(commit_tree_command).to(
          receive(:call)
          .with(tree_sha, m: "commit tree #{tree_sha}")
          .and_return(command_result(commit_sha))
          .ordered
        )
        result
      end

      it 'returns the commit SHA from stdout' do
        allow(write_tree_command).to receive(:call).and_return(command_result(tree_sha))
        allow(commit_tree_command).to receive(:call).and_return(command_result(commit_sha))
        expect(result).to eq(commit_sha)
      end
    end

    context 'with message option' do
      subject(:result) { described_instance.write_and_commit_tree(message: 'my commit') }

      it 'forwards options to commit_tree' do
        allow(write_tree_command).to receive(:call).and_return(command_result(tree_sha))
        expect(commit_tree_command).to receive(:call).with(tree_sha,
                                                           m: 'my commit').and_return(command_result(commit_sha))
        result
      end
    end
  end
end
