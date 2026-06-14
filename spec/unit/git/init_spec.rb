# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Git do
  describe '.init' do
    let(:git_repository) { instance_double(Git::Repository) }

    before do
      allow(Git::Repository).to receive(:init).and_return(git_repository)
    end

    it 'delegates to Git::Repository.init' do
      expect(Git::Repository).to receive(:init).with('my-repo', {}).and_return(git_repository)

      Git.init('my-repo')
    end

    it 'passes all options through to Git::Repository.init' do
      expect(Git::Repository).to receive(:init).with(
        'my-repo',
        { bare: true, initial_branch: 'main', git_ssh: 'custom-ssh' }
      ).and_return(git_repository)

      Git.init('my-repo', bare: true, initial_branch: 'main', git_ssh: 'custom-ssh')
    end

    it 'uses "." as the default directory' do
      expect(Git::Repository).to receive(:init).with('.', {}).and_return(git_repository)

      Git.init
    end

    it 'returns the Git::Repository returned by Git::Repository.init' do
      result = Git.init('my-repo')

      expect(result).to be(git_repository)
    end
  end
end
