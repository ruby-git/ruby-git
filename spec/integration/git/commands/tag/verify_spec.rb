# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/tag/verify'

RSpec.describe Git::Commands::Tag::Verify, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  describe '#call' do
    before do
      write_file('file.txt', 'content')
      repo.add('file.txt')
      repo.commit('Initial commit')
    end

    # Signed tag tests require GPG configuration which may not be available
    # in all CI environments. These tests are skipped unless GPG is configured.
    describe 'when the command succeeds', skip: 'Requires GPG configuration' do
      # To run these tests locally:
      # 1. Configure GPG: git config user.signingkey <your-gpg-key-id>
      # 2. Enable signing: git config tag.gpgsign true
      # 3. Create a signed tag: git tag -s v3.0.0 -m "Signed release"
    end

    describe 'when the command fails' do
      it 'raises FailedError for a non-existent tag' do
        expect { command.call('nonexistent') }.to raise_error(Git::FailedError)
      end
    end
  end
end
