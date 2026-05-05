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

  # ---------------------------------------------------------------------------
  # #local_branch?
  # ---------------------------------------------------------------------------

  describe '#local_branch?' do
    let(:list_command) { instance_double(Git::Commands::Branch::List) }

    before do
      allow(Git::Commands::Branch::List)
        .to receive(:new).with(execution_context).and_return(list_command)
    end

    context 'when the branch exists locally' do
      subject(:result) { described_instance.local_branch?('main') }

      it 'delegates to Branch::List#call with the branch name and short format' do
        expect(list_command)
          .to receive(:call).with('main', format: '%(refname:short)').and_return(command_result("main\n"))
        result
      end

      it 'returns true' do
        allow(list_command)
          .to receive(:call).with('main', format: '%(refname:short)').and_return(command_result("main\n"))
        expect(result).to be(true)
      end
    end

    context 'when the branch does not exist locally' do
      subject(:result) { described_instance.local_branch?('nonexistent') }

      it 'returns false' do
        allow(list_command)
          .to receive(:call).with('nonexistent', format: '%(refname:short)').and_return(command_result(''))
        expect(result).to be(false)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # #remote_branch?
  # ---------------------------------------------------------------------------

  describe '#remote_branch?' do
    let(:list_command) { instance_double(Git::Commands::Branch::List) }

    before do
      allow(Git::Commands::Branch::List)
        .to receive(:new).with(execution_context).and_return(list_command)
    end

    context 'when a remote tracking branch with that short name exists' do
      subject(:result) { described_instance.remote_branch?('master') }

      it 'delegates to Branch::List#call with remotes: true and lstrip format' do
        expect(list_command)
          .to receive(:call).with('*/master', remotes: true, format: '%(refname:lstrip=3)')
          .and_return(command_result("master\n"))
        result
      end

      it 'returns true' do
        allow(list_command)
          .to receive(:call).with('*/master', remotes: true, format: '%(refname:lstrip=3)')
          .and_return(command_result("master\n"))
        expect(result).to be(true)
      end
    end

    context 'when no remotes are configured' do
      subject(:result) { described_instance.remote_branch?('master') }

      it 'returns false' do
        allow(list_command)
          .to receive(:call).with('*/master', remotes: true, format: '%(refname:lstrip=3)')
          .and_return(command_result(''))
        expect(result).to be(false)
      end
    end

    context 'when the combined remote/branch name is passed (4.x compat)' do
      subject(:result) { described_instance.remote_branch?('origin/master') }

      it 'returns false because the list contains only short branch names' do
        allow(list_command)
          .to receive(:call).with('*/origin/master', remotes: true, format: '%(refname:lstrip=3)')
          .and_return(command_result("master\n"))
        expect(result).to be(false)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # #branch?
  # ---------------------------------------------------------------------------

  describe '#branch?' do
    let(:list_command) { instance_double(Git::Commands::Branch::List) }

    before do
      allow(Git::Commands::Branch::List)
        .to receive(:new).with(execution_context).and_return(list_command)
    end

    context 'when the branch exists locally' do
      subject(:result) { described_instance.branch?('main') }

      it 'returns true without calling git branch --remotes' do
        allow(list_command)
          .to receive(:call).with('main', format: '%(refname:short)')
          .and_return(command_result("main\n"))
        # remote_branch? should not be called when local_branch? returns true
        expect(list_command).not_to receive(:call).with(anything, remotes: true, format: '%(refname:lstrip=3)')
        expect(result).to be(true)
      end
    end

    context 'when the branch exists only as a remote tracking branch' do
      subject(:result) { described_instance.branch?('develop') }

      it 'returns true after checking both local and remote branches' do
        allow(list_command)
          .to receive(:call).with('develop', format: '%(refname:short)')
          .and_return(command_result(''))
        allow(list_command)
          .to receive(:call).with('*/develop', remotes: true, format: '%(refname:lstrip=3)')
          .and_return(command_result("develop\n"))
        expect(result).to be(true)
      end
    end

    context 'when the branch does not exist locally or remotely' do
      subject(:result) { described_instance.branch?('nonexistent') }

      it 'returns false after checking both local and remote branches' do
        allow(list_command)
          .to receive(:call).with('nonexistent', format: '%(refname:short)')
          .and_return(command_result(''))
        allow(list_command)
          .to receive(:call).with('*/nonexistent', remotes: true, format: '%(refname:lstrip=3)')
          .and_return(command_result("main\n"))
        expect(result).to be(false)
      end
    end

    context 'when passed a combined remote/branch name like origin/main' do
      subject(:result) { described_instance.branch?('origin/main') }

      it 'returns false (4.x compat: remote branches are matched by short name only)' do
        allow(list_command)
          .to receive(:call).with('origin/main', format: '%(refname:short)')
          .and_return(command_result(''))
        allow(list_command)
          .to receive(:call).with('*/origin/main', remotes: true, format: '%(refname:lstrip=3)')
          .and_return(command_result("main\n"))
        expect(result).to be(false)
      end
    end

    context 'when a local branch topic/main exists and querying main' do
      subject(:result) { described_instance.branch?('main') }

      it 'returns false (local slash-branch does not match short name)' do
        # git branch --list main only matches the exact name, not topic/main
        allow(list_command)
          .to receive(:call).with('main', format: '%(refname:short)')
          .and_return(command_result(''))
        allow(list_command)
          .to receive(:call).with('*/main', remotes: true, format: '%(refname:lstrip=3)')
          .and_return(command_result(''))
        expect(result).to be(false)
      end
    end
  end
end
