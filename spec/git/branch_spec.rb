# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Git::Branch do
  let(:lib) { instance_double(Git::Lib) }
  let(:base) { instance_double(Git::Base, lib: lib) }

  describe '#initialize' do
    context 'with a BranchInfo object for a local branch' do
      let(:branch_info) do
        Git::BranchInfo.new(
          refname: 'feature/my-feature',
          current: true,
          worktree: false,
          symref: nil
        )
      end

      subject(:branch) { described_class.new(base, branch_info) }

      it 'sets the full refname' do
        expect(branch.full).to eq('feature/my-feature')
      end

      it 'sets the short name' do
        expect(branch.name).to eq('feature/my-feature')
      end

      it 'has no remote' do
        expect(branch.remote).to be_nil
      end
    end

    context 'with a BranchInfo object for a remote branch' do
      let(:branch_info) do
        Git::BranchInfo.new(
          refname: 'remotes/origin/main',
          current: false,
          worktree: false,
          symref: nil
        )
      end

      let(:remote_config) { { 'url' => 'https://github.com/test/repo.git' } }

      subject(:branch) { described_class.new(base, branch_info) }

      before do
        allow(lib).to receive(:config_remote).with('origin').and_return(remote_config)
      end

      it 'sets the full refname' do
        expect(branch.full).to eq('remotes/origin/main')
      end

      it 'sets the short name without remote prefix' do
        expect(branch.name).to eq('main')
      end

      it 'creates a remote object' do
        expect(branch.remote).to be_a(Git::Remote)
        expect(branch.remote.name).to eq('origin')
      end
    end

    context 'with a String (legacy path)' do
      let(:remote_config) { { 'url' => 'https://github.com/test/repo.git' } }

      subject(:branch) { described_class.new(base, 'remotes/origin/develop') }

      before do
        allow(lib).to receive(:config_remote).with('origin').and_return(remote_config)
      end

      it 'sets the full refname' do
        expect(branch.full).to eq('remotes/origin/develop')
      end

      it 'sets the short name without remote prefix' do
        expect(branch.name).to eq('develop')
      end

      it 'creates a remote object' do
        expect(branch.remote).to be_a(Git::Remote)
        expect(branch.remote.name).to eq('origin')
      end
    end

    context 'equivalence between BranchInfo and String initialization' do
      let(:refname) { 'remotes/upstream/feature/test' }
      let(:remote_config) { { 'url' => 'https://github.com/test/repo.git' } }

      let(:branch_info) do
        Git::BranchInfo.new(
          refname: refname,
          current: false,
          worktree: false,
          symref: nil
        )
      end

      let(:branch_from_info) { described_class.new(base, branch_info) }
      let(:branch_from_string) { described_class.new(base, refname) }

      before do
        allow(lib).to receive(:config_remote).with('upstream').and_return(remote_config)
      end

      it 'produces equivalent full refname' do
        expect(branch_from_info.full).to eq(branch_from_string.full)
      end

      it 'produces equivalent short name' do
        expect(branch_from_info.name).to eq(branch_from_string.name)
      end

      it 'produces equivalent remote name' do
        if branch_from_info.remote
          expect(branch_from_info.remote.name).to eq(branch_from_string.remote.name)
        else
          expect(branch_from_string.remote).to be_nil
        end
      end
    end
  end
end
