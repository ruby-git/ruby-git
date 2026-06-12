# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Git::Base do
  shared_context 'with a stubbed facade_repository' do
    let(:described_instance) { described_class.new }
    let(:facade_repository) { instance_double(Git::Repository) }

    before do
      allow(described_instance).to receive(:facade_repository).and_return(facade_repository)
    end
  end

  describe '.config' do
    it 'returns Git::Config.instance (delegator for backward compatibility)' do
      expect(described_class.config).to be(Git::Config.instance)
    end
  end

  describe '#binary_path' do
    context 'when not specified' do
      subject(:base) { described_class.new }

      it 'defaults to :use_global_config' do
        expect(base.binary_path).to eq(:use_global_config)
      end
    end

    context 'when an explicit path is provided' do
      subject(:base) { described_class.new(binary_path: '/custom/git') }

      it 'returns the provided path' do
        expect(base.binary_path).to eq('/custom/git')
      end
    end

    context 'when binary_path is explicitly nil' do
      it 'raises ArgumentError' do
        expect { described_class.new(binary_path: nil) }.to raise_error(ArgumentError, /binary_path/)
      end
    end
  end

  describe '#full_log_commits' do
    include_context 'with a stubbed facade_repository'

    subject(:result) { described_instance.full_log_commits(opts) }

    let(:opts) { { count: 3 } }
    let(:log_data) { [{ 'sha' => 'abc123' }] }

    it 'delegates to facade_repository with opts and returns the facade result' do
      expect(facade_repository).to receive(:full_log_commits).with(opts).and_return(log_data)
      expect(result).to eq(log_data)
    end
  end

  describe '#log' do
    include_context 'with a stubbed facade_repository'

    subject(:result) { described_instance.log(count) }

    let(:count) { 5 }
    let(:log_instance) { instance_double(Git::Log) }

    before do
      allow(facade_repository).to receive(:log).with(count).and_return(log_instance)
    end

    it 'delegates to facade_repository.log with count and returns the result' do
      expect(facade_repository).to receive(:log).with(count).and_return(log_instance)
      expect(result).to be(log_instance)
    end

    context 'with default count' do
      subject(:result) { described_instance.log }

      before do
        allow(facade_repository).to receive(:log).with(30).and_return(log_instance)
      end

      it 'passes 30 as the default count' do
        expect(facade_repository).to receive(:log).with(30).and_return(log_instance)
        expect(result).to be(log_instance)
      end
    end
  end

  describe '#diff_stats' do
    include_context 'with a stubbed facade_repository'

    subject(:result) { described_instance.diff_stats(objectish, obj2, opts) }

    let(:objectish) { 'HEAD~1' }
    let(:obj2) { 'HEAD' }
    let(:opts) { { path_limiter: 'lib/' } }
    let(:diff_stats_result) { instance_double(Git::DiffStats) }

    it 'delegates to facade_repository.diff_stats with all arguments' do
      expect(facade_repository).to receive(:diff_stats).with(objectish, obj2, opts).and_return(diff_stats_result)
      expect(result).to be(diff_stats_result)
    end
  end

  describe '#diff' do
    include_context 'with a stubbed facade_repository'

    subject(:result) { described_instance.diff(objectish, obj2) }

    let(:objectish) { 'HEAD~1' }
    let(:obj2) { 'HEAD' }
    let(:diff_result) { instance_double(Git::Diff) }

    it 'delegates to facade_repository.diff with objectish and obj2' do
      expect(facade_repository).to receive(:diff).with(objectish, obj2).and_return(diff_result)
      expect(result).to be(diff_result)
    end

    context 'when called with default arguments' do
      subject(:result) { described_instance.diff }

      before do
        allow(facade_repository).to receive(:diff).with('HEAD', nil).and_return(diff_result)
      end

      it 'delegates to facade_repository.diff with HEAD and nil' do
        expect(facade_repository).to receive(:diff).with('HEAD', nil).and_return(diff_result)
        result
      end
    end
  end

  describe '#worktree' do
    include_context 'with a stubbed facade_repository'

    subject(:result) { described_instance.worktree(dir, commitish) }

    let(:dir) { '/tmp/feature' }
    let(:commitish) { 'main' }
    let(:worktree_double) { instance_double(Git::Worktree) }

    it 'delegates to facade_repository.worktree with dir and commitish' do
      expect(facade_repository).to receive(:worktree).with(dir, commitish).and_return(worktree_double)
      expect(result).to be(worktree_double)
    end

    context 'when called without a commitish' do
      let(:commitish) { nil }

      it 'delegates to facade_repository.worktree with nil as the commitish' do
        expect(facade_repository).to receive(:worktree).with(dir, nil).and_return(worktree_double)
        expect(result).to be(worktree_double)
      end
    end
  end

  describe '#worktrees' do
    include_context 'with a stubbed facade_repository'

    subject(:result) { described_instance.worktrees }

    let(:worktrees_collection) { instance_double(Git::Worktrees) }

    it 'delegates to facade_repository.worktrees' do
      expect(facade_repository).to receive(:worktrees).and_return(worktrees_collection)
      expect(result).to be(worktrees_collection)
    end
  end

  describe '#branch' do
    include_context 'with a stubbed facade_repository'

    subject(:result) { described_instance.branch(branch_name) }

    let(:branch_name) { 'feature' }
    let(:branch_double) { instance_double(Git::Branch) }

    it 'delegates to facade_repository.branch and returns the facade result unchanged' do
      expect(facade_repository).to receive(:branch).with(branch_name).and_return(branch_double)
      expect(result).to be(branch_double)
    end

    context 'when called without a branch name' do
      subject(:result) { described_instance.branch }

      it 'delegates to facade_repository.branch with the current branch as the default' do
        allow(described_instance).to receive(:current_branch).and_return('main')
        expect(facade_repository).to receive(:branch).with('main').and_return(branch_double)
        expect(result).to be(branch_double)
      end
    end
  end

  describe '#branches' do
    include_context 'with a stubbed facade_repository'

    subject(:result) { described_instance.branches }

    let(:branches_collection) { instance_double(Git::Branches) }

    it 'delegates to facade_repository.branches and returns the facade result unchanged' do
      expect(facade_repository).to receive(:branches).and_return(branches_collection)
      expect(result).to be(branches_collection)
    end
  end

  describe '#current_branch_state' do
    include_context 'with a stubbed facade_repository'

    it 'delegates to facade_repository.current_branch_state' do
      head_state = instance_double(Git::Repository::Branching::HeadState)
      expect(facade_repository).to receive(:current_branch_state).and_return(head_state)
      expect(described_instance.current_branch_state).to be(head_state)
    end
  end

  describe '#change_head_branch' do
    include_context 'with a stubbed facade_repository'

    it 'delegates to facade_repository.change_head_branch' do
      expect(facade_repository).to receive(:change_head_branch).with('new-branch')
      described_instance.change_head_branch('new-branch')
    end
  end

  describe '#gblob' do
    include_context 'with a stubbed facade_repository'

    subject(:result) { described_instance.gblob(objectish) }

    let(:objectish) { 'HEAD:README.md' }
    let(:object_double) { instance_double(Git::Object::Blob) }

    it 'delegates to facade_repository.gblob and returns the facade result unchanged' do
      expect(facade_repository).to receive(:gblob).with(objectish).and_return(object_double)
      expect(result).to be(object_double)
    end
  end

  describe '#gcommit' do
    include_context 'with a stubbed facade_repository'

    subject(:result) { described_instance.gcommit(objectish) }

    let(:objectish) { 'HEAD' }
    let(:object_double) { instance_double(Git::Object::Commit) }

    it 'delegates to facade_repository.gcommit and returns the facade result unchanged' do
      expect(facade_repository).to receive(:gcommit).with(objectish).and_return(object_double)
      expect(result).to be(object_double)
    end
  end

  describe '#gtree' do
    include_context 'with a stubbed facade_repository'

    subject(:result) { described_instance.gtree(objectish) }

    let(:objectish) { 'HEAD^{tree}' }
    let(:object_double) { instance_double(Git::Object::Tree) }

    it 'delegates to facade_repository.gtree and returns the facade result unchanged' do
      expect(facade_repository).to receive(:gtree).with(objectish).and_return(object_double)
      expect(result).to be(object_double)
    end
  end

  describe '#object' do
    include_context 'with a stubbed facade_repository'

    subject(:result) { described_instance.object(objectish) }

    let(:objectish) { 'HEAD' }
    let(:object_double) { instance_double(Git::Object::AbstractObject) }

    it 'delegates to facade_repository.object and returns the facade result unchanged' do
      expect(facade_repository).to receive(:object).with(objectish).and_return(object_double)
      expect(result).to be(object_double)
    end
  end

  describe '#remote' do
    include_context 'with a stubbed facade_repository'

    subject(:result) { described_instance.remote(remote_name) }

    let(:remote_name) { 'upstream' }
    let(:remote_double) { instance_double(Git::Remote) }

    it 'delegates to facade_repository.remote and returns the facade result unchanged' do
      expect(facade_repository).to receive(:remote).with(remote_name).and_return(remote_double)
      expect(result).to be(remote_double)
    end

    context 'when called without a remote name' do
      subject(:result) { described_instance.remote }

      it "delegates to facade_repository.remote with 'origin' as the default" do
        expect(facade_repository).to receive(:remote).with('origin').and_return(remote_double)
        expect(result).to be(remote_double)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Backward-compatibility yield values for block-based context helpers
  # Git::Base must yield the legacy Pathname values, not `self`.
  # ---------------------------------------------------------------------------

  describe '#with_index' do
    include_context 'with a stubbed facade_repository'

    let(:index_pathname) { Pathname.new('/repo/.git/custom-index') }

    before do
      allow(facade_repository).to receive(:with_index).and_yield(facade_repository)
      allow(facade_repository).to receive(:index).and_return(index_pathname)
    end

    it 'yields the active index Pathname for backward compatibility' do
      yielded = nil
      described_instance.with_index('/repo/.git/custom-index') { |v| yielded = v }
      expect(yielded).to eq(index_pathname)
    end

    it 'returns the block return value' do
      result = described_instance.with_index('/repo/.git/custom-index') { 42 }
      expect(result).to eq(42)
    end
  end

  describe '#with_temp_index' do
    include_context 'with a stubbed facade_repository'

    let(:temp_index_pathname) { Pathname.new('/tmp/temp-index-abcdef') }

    before do
      allow(facade_repository).to receive(:with_temp_index).and_yield(facade_repository)
      allow(facade_repository).to receive(:index).and_return(temp_index_pathname)
    end

    it 'yields the temporary index Pathname for backward compatibility' do
      yielded = nil
      described_instance.with_temp_index { |v| yielded = v }
      expect(yielded).to eq(temp_index_pathname)
    end
  end

  describe '#with_working' do
    include_context 'with a stubbed facade_repository'

    let(:work_dir_pathname) { Pathname.new('/tmp/work-dir') }

    before do
      allow(facade_repository).to receive(:with_working).and_yield(facade_repository)
      allow(facade_repository).to receive(:dir).and_return(work_dir_pathname)
    end

    it 'yields the active working directory Pathname for backward compatibility' do
      yielded = nil
      described_instance.with_working('/tmp/work-dir') { |v| yielded = v }
      expect(yielded).to eq(work_dir_pathname)
    end

    it 'returns the block return value' do
      result = described_instance.with_working('/tmp/work-dir') { 'done' }
      expect(result).to eq('done')
    end
  end

  describe '#with_temp_working' do
    include_context 'with a stubbed facade_repository'

    let(:temp_dir_pathname) { Pathname.new('/tmp/temp-workdir-xyz') }

    before do
      allow(facade_repository).to receive(:with_temp_working).and_yield(facade_repository)
      allow(facade_repository).to receive(:dir).and_return(temp_dir_pathname)
    end

    it 'yields the temporary working directory Pathname for backward compatibility' do
      yielded = nil
      described_instance.with_temp_working { |v| yielded = v }
      expect(yielded).to eq(temp_dir_pathname)
    end
  end

  describe '#branch_current' do
    it 'is an alias for #current_branch' do
      expect(described_class.instance_method(:branch_current)).to eq(described_class.instance_method(:current_branch))
    end
  end

  describe '#tag' do
    include_context 'with a stubbed facade_repository'

    subject(:result) { described_instance.tag(tag_name) }

    let(:tag_name) { 'v1.0.0' }
    let(:tag_double) { instance_double(Git::Object::Tag) }

    it 'delegates to facade_repository.tag and returns the facade result unchanged' do
      expect(facade_repository).to receive(:tag).with(tag_name).and_return(tag_double)
      expect(result).to be(tag_double)
    end
  end

  describe '#mv' do
    include_context 'with a stubbed facade_repository'

    it 'delegates to facade_repository.mv' do
      expect(facade_repository).to receive(:mv).with('old.rb', 'new.rb', {}).and_return('')
      expect(described_instance.mv('old.rb', 'new.rb')).to eq('')
    end
  end

  describe '#git_version' do
    context 'when binary_path is :use_global_config (default)' do
      it 'calls Git.git_version with no arguments' do
        version = instance_double(Git::Version)
        expect(Git).to receive(:git_version).with(no_args).and_return(version)
        expect(described_class.new.git_version).to be(version)
      end
    end

    context 'when binary_path is an explicit path' do
      it 'forwards binary_path to Git.git_version' do
        version = instance_double(Git::Version)
        expect(Git).to receive(:git_version).with('/usr/local/bin/git').and_return(version)
        expect(described_class.new(binary_path: '/usr/local/bin/git').git_version).to be(version)
      end
    end
  end

  describe '#ls_remote' do
    include_context 'with a stubbed facade_repository'

    it 'delegates to facade_repository.ls_remote' do
      result_hash = { 'head' => { ref: 'HEAD', sha: 'abc123' } }
      expect(facade_repository).to receive(:ls_remote).with(nil, {}).and_return(result_hash)
      expect(described_instance.ls_remote).to eq(result_hash)
    end
  end

  describe '#unmerged' do
    include_context 'with a stubbed facade_repository'

    it 'delegates to facade_repository.unmerged' do
      expect(facade_repository).to receive(:unmerged).and_return(['file.rb'])
      expect(described_instance.unmerged).to eq(['file.rb'])
    end
  end

  describe '#conflicts' do
    include_context 'with a stubbed facade_repository'

    before do
      allow(Git::Deprecation).to receive(:warn)
    end

    it 'emits a deprecation warning matching /conflicts is deprecated/' do
      allow(described_instance).to receive(:each_conflict).and_return([])
      expect(Git::Deprecation).to receive(:warn).with(/conflicts is deprecated/)
      described_instance.conflicts
    end

    it 'delegates to each_conflict, forwarding the block, and returns its return value' do
      expected_result = ['file.rb']
      the_block = proc {}
      captured_block = nil
      expect(described_instance).to receive(:each_conflict) do |&b|
        captured_block = b
        expected_result
      end
      result = described_instance.conflicts(&the_block)
      expect(captured_block).to be(the_block)
      expect(result).to eq(expected_result)
    end
  end

  describe '#stash_list' do
    include_context 'with a stubbed facade_repository'

    it 'delegates to facade_repository.stash_list' do
      expect(facade_repository).to receive(:stash_list).and_return('stash@{0}: WIP')
      expect(described_instance.stash_list).to eq('stash@{0}: WIP')
    end
  end

  describe '#global_config' do
    include_context 'with a stubbed facade_repository'

    it 'delegates to facade_repository.global_config with name and value' do
      expect(facade_repository).to receive(:global_config).with('user.name', 'Alice').and_return(nil)
      described_instance.global_config('user.name', 'Alice')
    end
  end

  describe '#config_get' do
    include_context 'with a stubbed facade_repository'

    it 'delegates to facade_repository.config_get' do
      expect(facade_repository).to receive(:config_get).with('user.name').and_return('Alice')
      expect(described_instance.config_get('user.name')).to eq('Alice')
    end
  end

  describe '#config_list' do
    include_context 'with a stubbed facade_repository'

    it 'delegates to facade_repository.config_list' do
      result = { 'user.name' => 'Alice' }
      expect(facade_repository).to receive(:config_list).and_return(result)
      expect(described_instance.config_list).to eq(result)
    end
  end

  describe '#config_set' do
    include_context 'with a stubbed facade_repository'

    it 'delegates to facade_repository.config_set' do
      set_result = instance_double(Git::CommandLineResult)
      expect(facade_repository).to receive(:config_set).with('user.name', 'Alice', {}).and_return(set_result)
      expect(described_instance.config_set('user.name', 'Alice')).to be(set_result)
    end
  end

  describe '#global_config_get' do
    include_context 'with a stubbed facade_repository'

    it 'delegates to facade_repository.global_config_get with name' do
      expect(facade_repository).to receive(:global_config_get).with('user.name').and_return('Alice')
      expect(described_instance.global_config_get('user.name')).to eq('Alice')
    end
  end

  describe '#global_config_list' do
    include_context 'with a stubbed facade_repository'

    it 'delegates to facade_repository.global_config_list' do
      result = { 'user.name' => 'Alice' }
      expect(facade_repository).to receive(:global_config_list).and_return(result)
      expect(described_instance.global_config_list).to eq(result)
    end
  end

  describe '#global_config_set' do
    include_context 'with a stubbed facade_repository'

    it 'delegates to facade_repository.global_config_set with name and value' do
      set_result = instance_double(Git::CommandLineResult)
      expect(facade_repository).to receive(:global_config_set).with('user.name', 'Alice').and_return(set_result)
      expect(described_instance.global_config_set('user.name', 'Alice')).to be(set_result)
    end
  end
end
