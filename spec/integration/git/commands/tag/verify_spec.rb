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

    context 'when the command fails' do
      it 'raises FailedError for a non-existent tag' do
        expect { command.call('nonexistent') }.to raise_error(Git::FailedError)
      end
    end
  end
end
