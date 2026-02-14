# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/tag/create'

RSpec.describe Git::Commands::Tag::Create, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  describe '#call' do
    before do
      write_file('file.txt', 'content')
      repo.add('file.txt')
      repo.commit('Initial commit')
    end

    describe 'when the command succeeds' do
      it 'returns a CommandLineResult' do
        result = command.call('v1.0.0')

        expect(result).to be_a(Git::CommandLineResult)
      end
    end

    describe 'when the command fails' do
      it 'raises FailedError when the tag already exists' do
        command.call('v1.0.0')

        expect { command.call('v1.0.0') }.to raise_error(Git::FailedError)
      end

      it 'raises FailedError when annotated tag is requested without a message' do
        expect { command.call('v1.0.0', annotate: true) }
          .to raise_error(Git::FailedError)
      end
    end
  end
end
