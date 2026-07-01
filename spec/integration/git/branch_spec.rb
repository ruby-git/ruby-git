# frozen_string_literal: true

require 'spec_helper'
require 'git/branch'

RSpec.describe Git::Branch, :integration do
  include_context 'in an empty repository'

  let(:bare_dir) { Dir.mktmpdir('bare_repo') }

  after do
    FileUtils.rm_rf(bare_dir)
  end

  before do
    write_file('README.md', "# Hello\n")
    repo.add('README.md')
    repo.commit('Initial commit')

    Git.init(bare_dir, bare: true)
    repo.remote_add('origin', bare_dir)
    repo.branch('feature').create
    repo.push('origin', 'feature')
  end

  describe '#delete' do
    context 'with a remote-tracking branch' do
      it 'deletes the remote-tracking ref without deleting the same-named local branch' do
        repo.branches['remotes/origin/feature'].delete

        expect(repo.branches.local.map(&:name)).to include('feature')
        expect(repo.branches.remote.map(&:full)).not_to include('remotes/origin/feature')
      end
    end

    context 'when the branch is the current branch' do
      before { repo.branch('feature').checkout }

      it 'raises Git::Error' do
        expect { repo.branch('feature').delete }.to raise_error(Git::Error, /cannot delete branch|checked out/)
      end
    end
  end

  describe '#create' do
    it 'creates the branch without switching to it' do
      repo.branch('new-branch').create

      expect(repo.branch('new-branch').current).to be(false)
      expect(repo.branches.local.map(&:name)).to include('new-branch')
    end
  end

  describe '#checkout' do
    it 'switches HEAD to the checked-out branch' do
      repo.branch('new-branch').create
      repo.branch('new-branch').checkout

      expect(repo.branch('new-branch').current).to be(true)
    end
  end
end
