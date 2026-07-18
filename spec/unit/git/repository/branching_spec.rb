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
  # HeadState
  # ---------------------------------------------------------------------------

  describe 'HeadState' do
    subject(:head_state_class) { Git::Repository::Branching::HeadState }

    it 'is a Data class' do
      expect(head_state_class).to be < Data
    end

    it 'constructs with keyword arguments' do
      instance = head_state_class.new(state: :active, name: 'main')
      expect(instance.state).to eq(:active)
      expect(instance.name).to eq('main')
    end

    it 'is immutable (does not respond to state=)' do
      instance = head_state_class.new(state: :active, name: 'main')
      expect(instance).not_to respond_to(:state=)
    end
  end

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
  # #current_branch_state
  # ---------------------------------------------------------------------------

  describe '#current_branch_state' do
    subject(:result) { described_instance.current_branch_state }

    let(:show_current_command) { instance_double(Git::Commands::Branch::ShowCurrent) }
    let(:rev_parse_command) { instance_double(Git::Commands::RevParse) }

    before do
      allow(Git::Commands::Branch::ShowCurrent)
        .to receive(:new).with(execution_context).and_return(show_current_command)
      allow(Git::Commands::RevParse)
        .to receive(:new).with(execution_context).and_return(rev_parse_command)
    end

    context 'when on an active branch (RevParse succeeds)' do
      before do
        allow(show_current_command).to receive(:call).and_return(command_result("main\n"))
        allow(rev_parse_command)
          .to receive(:call).with('main', verify: true, quiet: true)
          .and_return(command_result('abc123'))
      end

      it 'returns HeadState with state :active and the branch name' do
        expect(result).to eq(
          Git::Repository::Branching::HeadState.new(state: :active, name: 'main')
        )
      end
    end

    context 'when on an unborn branch (RevParse exits 1 with empty stderr)' do
      let(:unborn_result) { command_result('', stderr: '', exitstatus: 1) }

      before do
        allow(show_current_command).to receive(:call).and_return(command_result("main\n"))
        allow(rev_parse_command)
          .to receive(:call).with('main', verify: true, quiet: true)
          .and_raise(Git::FailedError.new(unborn_result))
      end

      it 'returns HeadState with state :unborn and the branch name' do
        expect(result).to eq(
          Git::Repository::Branching::HeadState.new(state: :unborn, name: 'main')
        )
      end
    end

    context 'in detached HEAD state (ShowCurrent returns empty stdout)' do
      before do
        allow(show_current_command).to receive(:call).and_return(command_result(''))
      end

      it 'returns HeadState with state :detached and name HEAD' do
        expect(result).to eq(
          Git::Repository::Branching::HeadState.new(state: :detached, name: 'HEAD')
        )
      end

      it 'does not call RevParse' do
        expect(rev_parse_command).not_to receive(:call)
        result
      end
    end

    context 'when RevParse exits 1 with non-empty stderr' do
      let(:error_result) { command_result('', stderr: 'fatal: not a git repository', exitstatus: 1) }

      before do
        allow(show_current_command).to receive(:call).and_return(command_result("main\n"))
        allow(rev_parse_command)
          .to receive(:call).with('main', verify: true, quiet: true)
          .and_raise(Git::FailedError.new(error_result))
      end

      it 're-raises the FailedError' do
        expect { result }.to raise_error(Git::FailedError)
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

    context 'with legacy new_branch: true and no start_point' do
      subject(:result) { described_instance.checkout('feature1', new_branch: true) }

      it 'passes a nil target and b: branch to the command' do
        expect(checkout_branch_command)
          .to receive(:call).with(nil, b: 'feature1').and_return(checkout_branch_result)
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

    context 'with options passed as the first argument' do
      it 'treats the hash as options and delegates without a branch' do
        expect(checkout_branch_command)
          .to receive(:call).with(nil, force: true).and_return(checkout_branch_result)
        described_instance.checkout(force: true)
      end
    end

    context 'with options passed as a bare Hash variable' do
      let(:opts) { { force: true } }

      subject(:result) { described_instance.checkout('main', opts) }

      it 'does not raise ArgumentError' do
        allow(checkout_branch_command)
          .to receive(:call).with('main', force: true).and_return(checkout_branch_result)
        expect { result }.not_to raise_error
      end

      it 'forwards the options to the command' do
        expect(checkout_branch_command)
          .to receive(:call).with('main', force: true).and_return(checkout_branch_result)
        result
      end
    end

    context 'with too many positional arguments' do
      it 'raises ArgumentError' do
        expect { described_instance.checkout('main', {}, :extra) }
          .to raise_error(ArgumentError)
      end
    end

    context 'with an unknown option' do
      subject(:result) { described_instance.checkout('main', bogus: true) }

      it 'raises ArgumentError' do
        expect { result }.to raise_error(ArgumentError, /Unknown options: bogus/)
      end

      it 'does not call the command' do
        expect(checkout_branch_command).not_to receive(:call)
        expect { result }.to raise_error(ArgumentError, /Unknown options: bogus/)
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

    context 'with an empty path_limiter' do
      it 'omits the path operand' do
        expect(checkout_index_command).to receive(:call).with(no_args).and_return(checkout_index_result)
        described_instance.checkout_index(path_limiter: '')
      end
    end

    context 'with an invalid path_limiter type' do
      it 'raises ArgumentError' do
        expect { described_instance.checkout_index(path_limiter: 123) }
          .to raise_error(ArgumentError, /Invalid path_limiter/)
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

  # ---------------------------------------------------------------------------
  # #branch_new
  # ---------------------------------------------------------------------------

  describe '#branch_new' do
    let(:create_command) { instance_double(Git::Commands::Branch::Create) }

    before do
      allow(Git::Commands::Branch::Create)
        .to receive(:new).with(execution_context).and_return(create_command)
    end

    context 'without a start_point' do
      subject(:result) { described_instance.branch_new('feature') }

      it 'delegates to Git::Commands::Branch::Create#call with the branch name and nil start_point' do
        expect(create_command).to receive(:call).with('feature', nil)
        result
      end

      it 'returns nil' do
        allow(create_command).to receive(:call).with('feature', nil)
        expect(result).to be_nil
      end
    end

    context 'with a start_point' do
      subject(:result) { described_instance.branch_new('feature', 'main') }

      it 'delegates to Git::Commands::Branch::Create#call with the branch name and start_point' do
        expect(create_command).to receive(:call).with('feature', 'main')
        result
      end

      it 'returns nil' do
        allow(create_command).to receive(:call).with('feature', 'main')
        expect(result).to be_nil
      end
    end

    context 'option whitelisting' do
      subject(:result) { described_instance.branch_new('feature', nil, bogus: true) }

      it 'raises ArgumentError for unsupported options' do
        expect { result }.to raise_error(ArgumentError, /Unknown options: bogus/)
      end

      it 'does not call the command' do
        expect(create_command).not_to receive(:call)
        expect { result }.to raise_error(ArgumentError, /Unknown options: bogus/)
      end
    end

    context 'when options are passed as the second argument (no start_point)' do
      subject(:result) { described_instance.branch_new('feature', bogus: true) }

      it 'raises ArgumentError for unsupported options' do
        expect { result }.to raise_error(ArgumentError, /Unknown options: bogus/)
      end

      it 'does not call the command' do
        expect(create_command).not_to receive(:call)
        expect { result }.to raise_error(ArgumentError, /Unknown options: bogus/)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # #branch_delete
  # ---------------------------------------------------------------------------

  describe '#branch_delete' do
    let(:delete_command) { instance_double(Git::Commands::Branch::Delete) }
    let(:delete_result) { command_result("Deleted branch feature (was abc1234).\n") }

    before do
      allow(Git::Commands::Branch::Delete)
        .to receive(:new).with(execution_context).and_return(delete_command)
    end

    context 'with a single branch name' do
      subject(:result) { described_instance.branch_delete('feature') }

      it 'delegates to Git::Commands::Branch::Delete#call with force: true by default' do
        expect(delete_command)
          .to receive(:call).with('feature', force: true).and_return(delete_result)
        result
      end

      it 'returns the stripped stdout' do
        allow(delete_command).to receive(:call).with('feature', force: true).and_return(delete_result)
        expect(result).to eq('Deleted branch feature (was abc1234).')
      end
    end

    context 'with multiple branch names' do
      subject(:result) { described_instance.branch_delete('feature-1', 'feature-2') }

      it 'passes all branch names to the command' do
        expect(delete_command)
          .to receive(:call).with('feature-1', 'feature-2', force: true).and_return(delete_result)
        result
      end
    end

    context 'with force: false' do
      subject(:result) { described_instance.branch_delete('feature', force: false) }

      it 'overrides the default force: true' do
        expect(delete_command)
          .to receive(:call).with('feature', force: false).and_return(delete_result)
        result
      end
    end

    context 'with remotes: true' do
      subject(:result) { described_instance.branch_delete('origin/feature', remotes: true) }

      it 'forwards remotes: true to the command alongside the default force: true' do
        expect(delete_command)
          .to receive(:call).with('origin/feature', force: true, remotes: true).and_return(delete_result)
        result
      end
    end

    context 'when the command exits non-zero' do
      subject(:result) { described_instance.branch_delete('nonexistent') }

      let(:failed_result) do
        command_result('', stderr: "error: branch 'nonexistent' not found.", exitstatus: 1)
      end

      it 'raises Git::Error with the stripped stderr message' do
        allow(delete_command)
          .to receive(:call).with('nonexistent', force: true).and_return(failed_result)
        expect { result }.to raise_error(Git::Error, "error: branch 'nonexistent' not found.")
      end
    end

    context 'with an unknown option' do
      subject(:result) { described_instance.branch_delete('feature', bogus: true) }

      it 'raises ArgumentError' do
        expect { result }.to raise_error(ArgumentError, /Unknown options: bogus/)
      end

      it 'does not call the command' do
        expect(delete_command).not_to receive(:call)
        expect { result }.to raise_error(ArgumentError, /Unknown options: bogus/)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # #change_head_branch
  # ---------------------------------------------------------------------------

  describe '#change_head_branch' do
    let(:update_command) { instance_double(Git::Commands::SymbolicRef::Update) }
    let(:update_result) { command_result('') }

    before do
      allow(Git::Commands::SymbolicRef::Update)
        .to receive(:new).with(execution_context).and_return(update_command)
    end

    context 'with a typical slash-separated branch name' do
      subject(:result) { described_instance.change_head_branch('feature/my-branch') }

      it 'constructs Git::Commands::SymbolicRef::Update with the execution context' do
        expect(Git::Commands::SymbolicRef::Update)
          .to receive(:new).with(execution_context).and_return(update_command)
        allow(update_command).to receive(:call).and_return(update_result)
        result
      end

      it "delegates to #call with 'HEAD' and 'refs/heads/feature/my-branch'" do
        expect(update_command)
          .to receive(:call).with('HEAD', 'refs/heads/feature/my-branch').and_return(update_result)
        result
      end

      it 'returns nil' do
        allow(update_command).to receive(:call).and_return(update_result)
        expect(result).to be_nil
      end
    end

    context 'with a simple branch name' do
      subject(:result) { described_instance.change_head_branch('main') }

      it "delegates to #call with 'HEAD' and 'refs/heads/main'" do
        expect(update_command)
          .to receive(:call).with('HEAD', 'refs/heads/main').and_return(update_result)
        result
      end
    end
  end

  # ---------------------------------------------------------------------------
  # #branch_contains
  # ---------------------------------------------------------------------------

  describe '#branch_contains' do
    let(:list_command) { instance_double(Git::Commands::Branch::List) }
    let(:list_result) { command_result("  main\n") }

    before do
      allow(Git::Commands::Branch::List)
        .to receive(:new).with(execution_context).and_return(list_command)
    end

    context 'when branch_name is omitted (default)' do
      subject(:result) { described_instance.branch_contains('abc1234') }

      it 'delegates to Branch::List#call without a pattern positional arg' do
        expect(list_command)
          .to receive(:call)
          .with(contains: 'abc1234', no_color: true)
          .and_return(list_result)
        result
      end

      it 'returns the stdout string' do
        allow(list_command)
          .to receive(:call)
          .with(contains: 'abc1234', no_color: true)
          .and_return(list_result)
        expect(result).to eq("  main\n")
      end
    end

    context 'when branch_name is a non-empty string' do
      subject(:result) { described_instance.branch_contains('abc1234', 'feature/*') }

      it 'delegates to Branch::List#call with the pattern as a positional arg' do
        expect(list_command)
          .to receive(:call)
          .with('feature/*', contains: 'abc1234', no_color: true)
          .and_return(list_result)
        result
      end
    end

    context 'when branch_name is an empty string' do
      subject(:result) { described_instance.branch_contains('abc1234', '') }

      it 'delegates without a pattern arg (same as omitting branch_name)' do
        expect(list_command)
          .to receive(:call)
          .with(contains: 'abc1234', no_color: true)
          .and_return(list_result)
        result
      end
    end

    context 'when branch_name is nil' do
      subject(:result) { described_instance.branch_contains('abc1234', nil) }

      it 'treats nil as empty string and delegates without a pattern arg' do
        expect(list_command)
          .to receive(:call)
          .with(contains: 'abc1234', no_color: true)
          .and_return(list_result)
        result
      end
    end

    context 'when no branches contain the commit (empty stdout)' do
      subject(:result) { described_instance.branch_contains('deadbeef') }

      it 'returns an empty string' do
        allow(list_command)
          .to receive(:call)
          .with(contains: 'deadbeef', no_color: true)
          .and_return(command_result(''))
        expect(result).to eq('')
      end
    end
  end

  # ---------------------------------------------------------------------------
  # #branch_list
  # ---------------------------------------------------------------------------

  describe '#branch_list' do
    subject(:result) { described_instance.branch_list(*patterns, **branch_list_options) }
    let(:patterns) { [] }
    let(:branch_list_options) { {} }
    let(:remote_names) { ['origin', 'team/upstream'] }

    let(:branch_list_command) { instance_double(Git::Commands::Branch::List) }
    let(:branch_list_result) do
      command_result("refs/heads/main|abc1234|*|||\nrefs/remotes/origin/main|abc1234||||\n")
    end
    let(:parsed_branches) do
      [
        instance_double(Git::BranchInfo, refname: 'main', current: true),
        instance_double(Git::BranchInfo, refname: 'remotes/origin/main', current: false)
      ]
    end

    before do
      allow(Git::Commands::Branch::List)
        .to receive(:new).with(execution_context).and_return(branch_list_command)
      allow(described_instance).to receive(:remote_names).and_return(remote_names)
    end

    context 'when the repository has branches' do
      it 'calls Branch::List#call then Git::Parsers::Branch.parse_list in order and returns the parsed result' do
        expect(branch_list_command).to(
          receive(:call)
            .with(all: true, format: Git::Parsers::Branch::FORMAT_STRING)
            .and_return(branch_list_result)
            .ordered
        )
        expect(Git::Parsers::Branch).to(
          receive(:parse_list)
            .with(branch_list_result.stdout, remote_names: remote_names)
            .and_return(parsed_branches)
            .ordered
        )
        expect(result).to eq(parsed_branches)
      end
    end

    context 'when the repository has no branches (empty stdout)' do
      let(:branch_list_result) { command_result('') }

      it 'calls Branch::List#call and Git::Parsers::Branch.parse_list with empty stdout and returns an empty array' do
        expect(branch_list_command).to(
          receive(:call)
            .with(all: true, format: Git::Parsers::Branch::FORMAT_STRING)
            .and_return(branch_list_result)
            .ordered
        )
        expect(Git::Parsers::Branch).to(
          receive(:parse_list)
            .with('', remote_names: remote_names)
            .and_return([])
            .ordered
        )
        expect(result).to eq([])
      end
    end

    context 'when a pattern is given' do
      let(:patterns) { ['foo'] }

      it 'passes the pattern as a positional argument to Branch::List#call' do
        expect(branch_list_command).to(
          receive(:call)
            .with('foo', all: true, format: Git::Parsers::Branch::FORMAT_STRING)
            .and_return(branch_list_result)
            .ordered
        )
        expect(Git::Parsers::Branch).to(
          receive(:parse_list)
            .with(branch_list_result.stdout, remote_names: remote_names)
            .and_return(parsed_branches)
            .ordered
        )
        expect(result).to eq(parsed_branches)
      end
    end

    context 'when remote_names is omitted' do
      it 'fetches configured remote names for parser resolution' do
        expect(described_instance).to receive(:remote_names).and_return(remote_names)
        allow(branch_list_command)
          .to receive(:call)
          .with(all: true, format: Git::Parsers::Branch::FORMAT_STRING)
          .and_return(branch_list_result)
        allow(Git::Parsers::Branch)
          .to receive(:parse_list)
          .with(branch_list_result.stdout, remote_names: remote_names)
          .and_return(parsed_branches)

        expect(result).to eq(parsed_branches)
      end
    end

    context 'when remote_names is given explicitly' do
      let(:explicit_remote_names) { ['team/upstream'] }
      let(:branch_list_options) { { remote_names: explicit_remote_names } }

      it 'uses the given remote names without querying the repository remotes' do
        expect(described_instance).not_to receive(:remote_names)
        allow(branch_list_command)
          .to receive(:call)
          .with(all: true, format: Git::Parsers::Branch::FORMAT_STRING)
          .and_return(branch_list_result)
        allow(Git::Parsers::Branch)
          .to receive(:parse_list)
          .with(branch_list_result.stdout, remote_names: explicit_remote_names)
          .and_return(parsed_branches)

        expect(result).to eq(parsed_branches)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # #branches_all (deprecated)
  # ---------------------------------------------------------------------------

  describe '#branches_all' do
    subject(:result) { described_instance.branches_all }

    let(:branch_list_command) { instance_double(Git::Commands::Branch::List) }
    let(:branch_list_result) { command_result("refs/heads/main\0abc1234\0*\0\0\0\n") }

    before do
      allow(Git::Commands::Branch::List)
        .to receive(:new).with(execution_context).and_return(branch_list_command)
      allow(described_instance).to receive(:remote_names).and_return(['origin'])
      allow(branch_list_command)
        .to receive(:call)
        .with(all: true, format: Git::Parsers::Branch::FORMAT_STRING)
        .and_return(branch_list_result)
    end

    it 'emits a deprecation warning' do
      expect(Git::Deprecation).to receive(:warn).with(/branches_all.*deprecated.*branch_list/i)
      result
    end

    it 'returns an array of 4-element arrays [refname, current, worktree, symref]' do
      allow(Git::Deprecation).to receive(:warn)
      expect(result).to eq([['main', true, false, nil]])
    end

    context 'with a remote-tracking branch' do
      let(:branch_list_result) do
        command_result("refs/remotes/origin/main\0abc1234\0\0\0\0\n")
      end

      it 'formats the refname as remotes/<remote>/<branch>' do
        allow(Git::Deprecation).to receive(:warn)
        expect(result).to eq([['remotes/origin/main', false, false, nil]])
      end
    end
  end

  # ---------------------------------------------------------------------------
  # #update_ref
  # ---------------------------------------------------------------------------

  describe '#update_ref' do
    subject(:result) { described_instance.update_ref('feature', 'abc1234') }

    let(:update_ref_command) { instance_double(Git::Commands::UpdateRef::Update) }
    let(:update_ref_result) { command_result }

    before do
      allow(Git::Commands::UpdateRef::Update)
        .to receive(:new).with(execution_context).and_return(update_ref_command)
      allow(update_ref_command)
        .to receive(:call).with('refs/heads/feature', 'abc1234').and_return(update_ref_result)
    end

    it 'constructs the full ref from the branch name and delegates to Git::Commands::UpdateRef::Update#call' do
      expect(update_ref_command)
        .to receive(:call).with('refs/heads/feature', 'abc1234').and_return(update_ref_result)
      result
    end

    it 'returns the Git::CommandLine::Result from the command' do
      expect(result).to eq(update_ref_result)
    end

    context 'when branch is a remotes/<remote>/<name> remote-tracking branch name' do
      subject(:result) { described_instance.update_ref('remotes/origin/main', 'abc1234') }

      before do
        allow(update_ref_command)
          .to receive(:call).with('refs/remotes/origin/main', 'abc1234').and_return(update_ref_result)
      end

      it 'routes to refs/remotes/<remote>/<name> for backward compatibility' do
        expect(update_ref_command)
          .to receive(:call).with('refs/remotes/origin/main', 'abc1234').and_return(update_ref_result)
        result
      end
    end

    context 'when branch is a refs/remotes/<remote>/<name> remote-tracking branch name' do
      subject(:result) { described_instance.update_ref('refs/remotes/origin/main', 'abc1234') }

      before do
        allow(update_ref_command)
          .to receive(:call).with('refs/remotes/origin/main', 'abc1234').and_return(update_ref_result)
      end

      it 'routes to refs/remotes/<remote>/<name> for backward compatibility' do
        expect(update_ref_command)
          .to receive(:call).with('refs/remotes/origin/main', 'abc1234').and_return(update_ref_result)
        result
      end
    end
  end

  # ---------------------------------------------------------------------------
  # #branch
  # ---------------------------------------------------------------------------

  describe '#branch' do
    let(:show_current_command) { instance_double(Git::Commands::Branch::ShowCurrent) }

    before do
      allow(Git::Commands::Branch::ShowCurrent)
        .to receive(:new).with(execution_context).and_return(show_current_command)
    end

    context 'with an explicit branch name' do
      subject(:result) { described_instance.branch('feature') }

      it 'returns a Git::Branch for the given name' do
        expect(result).to be_a(Git::Branch)
      end

      it 'sets the full refname to the given branch name' do
        expect(result.full).to eq('feature')
      end

      it 'sets the short name to the given branch name' do
        expect(result.name).to eq('feature')
      end

      it 'has no remote' do
        expect(result.remote).to be_nil
      end
    end

    context 'when no name is given (defaults to current_branch)' do
      subject(:result) { described_instance.branch }

      let(:show_current_result) { command_result("main\n") }

      before do
        allow(show_current_command).to receive(:call).and_return(show_current_result)
      end

      it 'returns a Git::Branch for the current branch name' do
        expect(result).to be_a(Git::Branch)
        expect(result.full).to eq('main')
      end
    end
  end

  # ---------------------------------------------------------------------------
  # #branches
  # ---------------------------------------------------------------------------

  describe '#branches' do
    subject(:result) { described_instance.branches }

    let(:branches_collection) { instance_double(Git::Branches) }

    it 'constructs Git::Branches with self and returns the collection' do
      expect(Git::Branches).to receive(:new).with(described_instance).and_return(branches_collection)
      expect(result).to eq(branches_collection)
    end
  end

  # ---------------------------------------------------------------------------
  # #is_local_branch? (deprecated)
  # ---------------------------------------------------------------------------

  describe '#is_local_branch?' do
    subject(:result) { described_instance.is_local_branch?('main') }

    let(:list_command) { instance_double(Git::Commands::Branch::List) }

    before do
      allow(Git::Commands::Branch::List)
        .to receive(:new).with(execution_context).and_return(list_command)
      allow(list_command)
        .to receive(:call).with('main', format: '%(refname:short)').and_return(command_result("main\n"))
      allow(Git::Deprecation).to receive(:warn)
    end

    it 'emits a deprecation warning mentioning is_local_branch? and local_branch?' do
      expect(Git::Deprecation).to receive(:warn).with(
        'Git::Repository#is_local_branch? is deprecated and will be removed in v6.0.0. ' \
        'Use Git::Repository#local_branch? instead.'
      )
      result
    end

    it 'returns true when the branch exists locally' do
      expect(result).to be(true)
    end

    context 'when the branch does not exist locally' do
      subject(:result) { described_instance.is_local_branch?('no-such-branch') }

      before do
        allow(list_command)
          .to receive(:call).with('no-such-branch', format: '%(refname:short)').and_return(command_result(''))
      end

      it 'returns false' do
        expect(result).to be(false)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # #is_remote_branch? (deprecated)
  # ---------------------------------------------------------------------------

  describe '#is_remote_branch?' do
    subject(:result) { described_instance.is_remote_branch?('master') }

    let(:list_command) { instance_double(Git::Commands::Branch::List) }

    before do
      allow(Git::Commands::Branch::List)
        .to receive(:new).with(execution_context).and_return(list_command)
      allow(list_command)
        .to receive(:call).with('*/master', remotes: true, format: '%(refname:lstrip=3)')
        .and_return(command_result("master\n"))
      allow(Git::Deprecation).to receive(:warn)
    end

    it 'emits a deprecation warning mentioning is_remote_branch? and remote_branch?' do
      expect(Git::Deprecation).to receive(:warn).with(
        'Git::Repository#is_remote_branch? is deprecated and will be removed in v6.0.0. ' \
        'Use Git::Repository#remote_branch? instead.'
      )
      result
    end

    it 'returns true when the remote tracking branch exists' do
      expect(result).to be(true)
    end

    context 'when the branch does not exist remotely' do
      subject(:result) { described_instance.is_remote_branch?('no-such-branch') }

      before do
        allow(list_command)
          .to receive(:call).with('*/no-such-branch', remotes: true, format: '%(refname:lstrip=3)')
          .and_return(command_result(''))
      end

      it 'returns false' do
        expect(result).to be(false)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # #is_branch? (deprecated)
  # ---------------------------------------------------------------------------

  describe '#is_branch?' do
    subject(:result) { described_instance.is_branch?('main') }

    let(:list_command) { instance_double(Git::Commands::Branch::List) }

    before do
      allow(Git::Commands::Branch::List)
        .to receive(:new).with(execution_context).and_return(list_command)
      allow(list_command)
        .to receive(:call).with('main', format: '%(refname:short)').and_return(command_result("main\n"))
      allow(Git::Deprecation).to receive(:warn)
    end

    it 'emits a deprecation warning mentioning is_branch? and branch?' do
      expect(Git::Deprecation).to receive(:warn).with(
        'Git::Repository#is_branch? is deprecated and will be removed in v6.0.0. ' \
        'Use Git::Repository#branch? instead.'
      )
      result
    end

    it 'returns true when the branch exists locally' do
      expect(result).to be(true)
    end

    context 'when the branch exists only remotely' do
      subject(:result) { described_instance.is_branch?('develop') }

      before do
        allow(list_command)
          .to receive(:call).with('develop', format: '%(refname:short)').and_return(command_result(''))
        allow(list_command)
          .to receive(:call).with('*/develop', remotes: true, format: '%(refname:lstrip=3)')
          .and_return(command_result("develop\n"))
      end

      it 'returns true' do
        expect(result).to be(true)
      end
    end

    context 'when the branch does not exist locally or remotely' do
      subject(:result) { described_instance.is_branch?('nonexistent') }

      before do
        allow(list_command)
          .to receive(:call).with('nonexistent', format: '%(refname:short)').and_return(command_result(''))
        allow(list_command)
          .to receive(:call).with('*/nonexistent', remotes: true, format: '%(refname:lstrip=3)')
          .and_return(command_result(''))
      end

      it 'returns false' do
        expect(result).to be(false)
      end
    end
  end
end
