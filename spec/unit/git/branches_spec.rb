# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Git::Branches do
  def make_branch_info(refname:, current: false, remote_name: :not_given)
    branch_info_args = {
      refname: refname,
      target_oid: nil,
      current: current,
      worktree_path: nil,
      symref: nil,
      upstream: nil
    }
    branch_info_args[:remote_name] = remote_name unless remote_name == :not_given

    Git::BranchInfo.new(**branch_info_args)
  end

  let(:local_info) { make_branch_info(refname: 'main', current: true) }
  let(:remote_info) { make_branch_info(refname: 'remotes/origin/main') }
  let(:slash_remote_info) do
    make_branch_info(refname: 'refs/remotes/team/upstream/main', remote_name: 'team/upstream')
  end

  let(:local_branch) do
    instance_double(Git::Branch, full: 'main', name: 'main', remote: nil, current: true, to_s: 'main')
  end
  let(:remote_branch) do
    instance_double(
      Git::Branch,
      full: 'remotes/origin/main', name: 'main',
      remote: instance_double(Git::Remote), current: false, to_s: 'remotes/origin/main'
    )
  end

  # ---------------------------------------------------------------------------
  # #initialize
  # ---------------------------------------------------------------------------

  describe '#initialize' do
    context 'when passed a Git::Repository' do
      let(:base) { instance_double(Git::Repository) }

      before do
        allow(Git::Deprecation).to receive(:warn)
        allow(base).to receive(:branch_list).and_return([local_info, remote_info])
        allow(Git::Branch).to receive(:new).with(base, local_info).and_return(local_branch)
        allow(Git::Branch).to receive(:new).with(base, remote_info).and_return(remote_branch)
      end

      it 'emits a deprecation warning via Git::Deprecation.warn' do
        expect(Git::Deprecation).to receive(:warn).with(
          'Git::Branches is deprecated and will be removed in v6.0.0. ' \
          'Use Git::Repository#branch_list instead.'
        )
        described_class.new(base)
      end

      it 'calls branch_list directly on the base' do
        expect(base).to receive(:branch_list).and_return([local_info, remote_info])
        described_class.new(base)
      end

      it 'creates a Git::Branch for each BranchInfo with the original base' do
        expect(Git::Branch).to receive(:new).with(base, local_info).and_return(local_branch)
        expect(Git::Branch).to receive(:new).with(base, remote_info).and_return(remote_branch)
        described_class.new(base)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Collection helpers: a Git::Branches with two known branches
  # ---------------------------------------------------------------------------

  let(:branch_infos) { [local_info, remote_info] }
  let(:repo_base) { instance_double(Git::Repository) }
  let(:described_instance) { described_class.new(repo_base) }

  before do
    allow(Git::Deprecation).to receive(:warn)
    allow(repo_base).to receive(:branch_list).and_return(branch_infos)
    allow(Git::Branch).to receive(:new).with(repo_base, local_info).and_return(local_branch)
    allow(Git::Branch).to receive(:new).with(repo_base, remote_info).and_return(remote_branch)
  end

  # ---------------------------------------------------------------------------
  # #local
  # ---------------------------------------------------------------------------

  describe '#local' do
    subject(:result) { described_instance.local }

    it 'returns only non-remote branches' do
      expect(result).to eq([local_branch])
    end
  end

  # ---------------------------------------------------------------------------
  # #remote
  # ---------------------------------------------------------------------------

  describe '#remote' do
    subject(:result) { described_instance.remote }

    it 'returns only remote-tracking branches' do
      expect(result).to eq([remote_branch])
    end
  end

  # ---------------------------------------------------------------------------
  # #size
  # ---------------------------------------------------------------------------

  describe '#size' do
    subject(:result) { described_instance.size }

    it 'returns the total number of branches' do
      expect(result).to eq(2)
    end

    context 'when the branch list is empty' do
      let(:branch_infos) { [] }

      it 'returns 0' do
        expect(result).to eq(0)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # #each
  # ---------------------------------------------------------------------------

  describe '#each' do
    subject(:result) { described_instance.each }

    it 'yields every branch in the collection' do
      expect(result.to_a).to contain_exactly(local_branch, remote_branch)
    end

    it 'returns an Enumerator when called without a block' do
      expect(result).to be_an(Enumerator)
    end
  end

  # ---------------------------------------------------------------------------
  # #[]
  # ---------------------------------------------------------------------------

  describe '#[]' do
    subject(:result) { described_instance[branch_name] }

    let(:branch_name) { 'main' }

    context 'with the exact refname of a local branch' do
      it 'returns the matching branch' do
        expect(result).to eq(local_branch)
      end
    end

    context 'with the full refname of a remote-tracking branch' do
      let(:branch_name) { 'remotes/origin/main' }

      it 'returns the matching remote branch' do
        expect(result).to eq(remote_branch)
      end
    end

    context 'with the short form of a remote-tracking branch (omitting "remotes/")' do
      let(:branch_name) { 'origin/main' }

      it 'returns the remote branch' do
        expect(result).to eq(remote_branch)
      end

      it 'does not change the collection size' do
        expect { result }.not_to change(described_instance, :size)
      end

      it 'does not duplicate branches in enumeration' do
        result

        expect(described_instance.map(&:full)).to contain_exactly('main', 'remotes/origin/main')
      end
    end

    context 'with the short form of a slash-remote branch' do
      let(:branch_infos) { [local_info, slash_remote_info] }
      let(:branch_name) { 'team/upstream/main' }

      before do
        allow(repo_base).to receive(:config_remote).with('team/upstream').and_return({})
        allow(Git::Branch).to receive(:new).with(repo_base, slash_remote_info).and_call_original
      end

      it 'returns the remote branch' do
        expect(result).to have_attributes(
          full: 'remotes/team/upstream/main',
          name: 'main',
          remote: have_attributes(name: 'team/upstream')
        )
      end

      it 'indexes the branch with the full remotes-prefixed name' do
        expect(described_instance['remotes/team/upstream/main']).to equal(result)
      end
    end

    context 'with an unknown branch name' do
      let(:branch_name) { 'nonexistent' }

      it 'returns nil' do
        expect(result).to be_nil
      end
    end

    context 'with a non-String argument' do
      let(:branch_name) { :main }

      it 'coerces to string via to_s and returns the matching branch' do
        expect(result).to eq(local_branch)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # #to_s
  # ---------------------------------------------------------------------------

  describe '#to_s' do
    subject(:result) { described_instance.to_s }

    it 'marks the current branch with "* "' do
      expect(result).to include('* main')
    end

    it 'marks non-current branches with two spaces' do
      expect(result).to include('  remotes/origin/main')
    end

    context 'when the branches are real Git::Branch objects' do
      let(:branch_infos) { [local_info] }
      let(:messages) { [] }

      # Route real warnings to a collector so the silence around the nested
      # deprecated call is exercised instead of bypassed by the stubbed
      # Git::Deprecation.warn
      around do |example|
        original_behavior = Git::Deprecation.behavior
        Git::Deprecation.behavior = ->(message, *) { messages << message }
        example.run
      ensure
        Git::Deprecation.behavior = original_behavior
      end

      before do
        allow(Git::Deprecation).to receive(:warn).and_call_original
        allow(Git::Branch).to receive(:new).with(repo_base, local_info).and_call_original
        allow(repo_base).to receive(:current_branch).and_return('main')
      end

      it 'lets only the Git::Branches warning escape' do
        expect(result).to eq("* main\n")
        expect(messages).to contain_exactly(a_string_including('Git::Branches is deprecated'))
      end
    end
  end
end
