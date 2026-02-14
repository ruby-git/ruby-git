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

      it 'verifies a signed tag successfully' do
        # This would need:
        # repo.add_tag('v3.0.0', sign: true, message: 'Signed release')
        # result = command.call('v3.0.0')
        # expect(result.stdout).to include('Good signature')
      end
    end

    describe 'when the command fails' do
      it 'raises FailedError for an unsigned lightweight tag' do
        repo.add_tag('v1.0.0')

        expect { command.call('v1.0.0') }.to raise_error(Git::FailedError)
      end

      it 'raises FailedError for an unsigned annotated tag' do
        repo.add_tag('v2.0.0', annotate: true, message: 'Release version 2.0.0')

        expect { command.call('v2.0.0') }.to raise_error(Git::FailedError)
      end

      it 'raises FailedError for a non-existent tag' do
        expect { command.call('nonexistent') }.to raise_error(Git::FailedError)
      end

      it 'raises FailedError when any tag is unsigned' do
        repo.add_tag('v1.0.0')
        repo.add_tag('v2.0.0', annotate: true, message: 'Release 2.0')

        expect { command.call('v1.0.0', 'v2.0.0') }.to raise_error(Git::FailedError)
      end

      it 'raises FailedError with format option on unsigned tag' do
        repo.add_tag('v1.0.0')

        # Format option is still passed through even when verification fails
        expect { command.call('v1.0.0', format: '%(refname:short)') }.to raise_error(Git::FailedError)
      end
    end
  end
end
