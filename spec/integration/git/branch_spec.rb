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
  end
end
