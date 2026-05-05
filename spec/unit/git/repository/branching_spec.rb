# frozen_string_literal: true

require 'spec_helper'
require 'git/repository'
require 'git/repository/branching'

# Integration-level coverage for Git::Repository::Branching is provided by
# spec/integration/git/repository/branching_spec.rb.
# The unit specs below cover the facade's own orchestration (argument pre-processing,
# option whitelisting, delegation contracts).

RSpec.describe Git::Repository::Branching do
  let(:execution_context) { instance_double(Git::ExecutionContext::Repository) }
  let(:described_instance) { Git::Repository.new(execution_context: execution_context) }

  # ---------------------------------------------------------------------------
  # #current_branch
  # ---------------------------------------------------------------------------

  describe '#current_branch' do
    subject(:result) { described_instance.current_branch }

    let(:show_current_command) { instance_double(Git::Commands::Branch::ShowCurrent) }

    before do
      allow(Git::Commands::Branch::ShowCurrent)
        .to receive(:new).with(execution_context).and_return(show_current_command)
    end

    context 'when on a normal branch' do
      let(:show_current_result) { command_result("main\n") }

      it 'delegates to Git::Commands::Branch::ShowCurrent#call' do
        expect(show_current_command).to receive(:call).and_return(show_current_result)
        result
      end

      it 'returns the stripped branch name' do
        allow(show_current_command).to receive(:call).and_return(show_current_result)
        expect(result).to eq('main')
      end
    end

    context 'when in detached HEAD state (empty stdout)' do
      let(:show_current_result) { command_result('') }

      it "returns 'HEAD'" do
        allow(show_current_command).to receive(:call).and_return(show_current_result)
        expect(result).to eq('HEAD')
      end
    end
  end

  # ---------------------------------------------------------------------------
  # #checkout_file
  # ---------------------------------------------------------------------------

  describe '#checkout_file' do
    subject(:result) { described_instance.checkout_file('HEAD', 'README.md') }

    let(:checkout_files_command) { instance_double(Git::Commands::Checkout::Files) }
    let(:checkout_files_result) { command_result('') }

    before do
      allow(Git::Commands::Checkout::Files)
        .to receive(:new).with(execution_context).and_return(checkout_files_command)
    end

    it 'delegates to Git::Commands::Checkout::Files#call with the tree-ish and pathspec' do
      expect(checkout_files_command)
        .to receive(:call).with('HEAD', pathspec: ['README.md']).and_return(checkout_files_result)
      result
    end

    it 'returns the command stdout' do
      allow(checkout_files_command)
        .to receive(:call).with('HEAD', pathspec: ['README.md']).and_return(checkout_files_result)
      expect(result).to eq('')
    end
  end

  # ---------------------------------------------------------------------------
  # #checkout
  # ---------------------------------------------------------------------------

  describe '#checkout' do
    let(:checkout_branch_command) { instance_double(Git::Commands::Checkout::Branch) }
    let(:checkout_branch_result) { command_result('') }

    before do
      allow(Git::Commands::Checkout::Branch)
        .to receive(:new).with(execution_context).and_return(checkout_branch_command)
    end

    context 'with no arguments' do
      subject(:result) { described_instance.checkout }

      it 'delegates to Git::Commands::Checkout::Branch#call with nil branch and no options' do
        expect(checkout_branch_command).to receive(:call).with(nil).and_return(checkout_branch_result)
        result
      end

      it 'returns the command stdout' do
        allow(checkout_branch_command).to receive(:call).with(nil).and_return(checkout_branch_result)
        expect(result).to eq('')
      end
    end

    context 'with a branch name' do
      subject(:result) { described_instance.checkout('main') }

      it 'delegates with the branch name' do
        expect(checkout_branch_command).to receive(:call).with('main').and_return(checkout_branch_result)
        result
      end
    end

    context 'with force: true' do
      subject(:result) { described_instance.checkout('main', force: true) }

      it 'forwards force: true to the command' do
        expect(checkout_branch_command)
          .to receive(:call).with('main', force: true).and_return(checkout_branch_result)
        result
      end
    end

    context 'with legacy new_branch: true and start_point option' do
      subject(:result) { described_instance.checkout('new-branch', new_branch: true, start_point: 'main') }

      it 'translates to call(start_point, b: branch)' do
        expect(checkout_branch_command)
          .to receive(:call).with('main', b: 'new-branch').and_return(checkout_branch_result)
        result
      end
    end

    context 'with legacy b: true and start_point option' do
      subject(:result) { described_instance.checkout('new-branch', b: true, start_point: 'main') }

      it 'translates to call(start_point, b: branch)' do
        expect(checkout_branch_command)
          .to receive(:call).with('main', b: 'new-branch').and_return(checkout_branch_result)
        result
      end
    end

    context 'with legacy new_branch: String option' do
      subject(:result) { described_instance.checkout('main', new_branch: 'new-feature') }

      it 'translates to call(branch, b: new_branch_name)' do
        expect(checkout_branch_command)
          .to receive(:call).with('main', b: 'new-feature').and_return(checkout_branch_result)
        result
      end
    end

    context 'with an unknown option' do
      subject(:result) { described_instance.checkout('main', bogus: true) }

      it 'raises ArgumentError' do
        expect { result }.to raise_error(ArgumentError, /Unknown options: bogus/)
      end

      it 'does not call the command' do
        expect(checkout_branch_command).not_to receive(:call)
        begin
          result
        rescue ArgumentError
          # expected
        end
      end
    end
  end

  # ---------------------------------------------------------------------------
  # #checkout_index
  # ---------------------------------------------------------------------------

  describe '#checkout_index' do
    let(:checkout_index_command) { instance_double(Git::Commands::CheckoutIndex) }
    let(:checkout_index_result) { command_result('') }

    before do
      allow(Git::Commands::CheckoutIndex)
        .to receive(:new).with(execution_context).and_return(checkout_index_command)
    end

    context 'with no arguments' do
      subject(:result) { described_instance.checkout_index }

      it 'delegates to Git::Commands::CheckoutIndex#call with no args' do
        expect(checkout_index_command).to receive(:call).with(no_args).and_return(checkout_index_result)
        result
      end

      it 'returns stdout as a String' do
        allow(checkout_index_command).to receive(:call).with(no_args).and_return(checkout_index_result)
        expect(result).to eq('')
      end
    end

    context 'with all: true' do
      subject(:result) { described_instance.checkout_index(all: true) }

      it 'forwards the option to the command' do
        expect(checkout_index_command).to receive(:call).with(all: true).and_return(checkout_index_result)
        result
      end
    end

    context 'with force: true' do
      subject(:result) { described_instance.checkout_index(force: true) }

      it 'forwards the option to the command' do
        expect(checkout_index_command).to receive(:call).with(force: true).and_return(checkout_index_result)
        result
      end
    end

    context 'with prefix: value' do
      subject(:result) { described_instance.checkout_index(prefix: 'tmp/') }

      it 'forwards the option to the command' do
        expect(checkout_index_command)
          .to receive(:call).with(prefix: 'tmp/').and_return(checkout_index_result)
        result
      end
    end

    context 'with path_limiter as a String' do
      subject(:result) { described_instance.checkout_index(path_limiter: 'README.md') }

      it 'converts path_limiter to a positional operand' do
        expect(checkout_index_command)
          .to receive(:call).with('README.md').and_return(checkout_index_result)
        result
      end
    end

    context 'with path_limiter as an Array' do
      subject(:result) { described_instance.checkout_index(path_limiter: ['a.rb', 'b.rb']) }

      it 'splatts each path as a separate operand' do
        expect(checkout_index_command)
          .to receive(:call).with('a.rb', 'b.rb').and_return(checkout_index_result)
        result
      end
    end

    context 'with path_limiter and force: true' do
      subject(:result) { described_instance.checkout_index(path_limiter: 'foo.rb', force: true) }

      it 'passes the path as operand and force as keyword option' do
        expect(checkout_index_command)
          .to receive(:call).with('foo.rb', force: true).and_return(checkout_index_result)
        result
      end
    end

    context 'with an unknown option' do
      subject(:result) { described_instance.checkout_index(bogus: true) }

      it 'raises ArgumentError' do
        expect { result }.to raise_error(ArgumentError, /Unknown options: bogus/)
      end
    end
  end
end
