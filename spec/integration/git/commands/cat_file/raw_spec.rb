# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/cat_file/raw'

RSpec.describe Git::Commands::CatFile::Raw, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  before do
    write_file('README.md', "# Hello\n")
    repo.add('README.md')
    repo.commit('Initial commit')
  end

  describe '#call' do
    context 'when the command succeeds' do
      context 'with -e mode' do
        it 'returns exit status 0 when the object exists' do
          result = command.call('HEAD', e: true)

          expect(result).to be_a(Git::CommandLine::Result)
          expect(result.status.exitstatus).to eq(0)
        end

        it 'returns exit status 1 when the object does not exist' do
          result = command.call('0000000000000000000000000000000000000000', e: true)

          expect(result.status.exitstatus).to eq(1)
        end
      end
    end

    context 'when the command fails' do
      it 'raises FailedError when the type does not match the object type' do
        # git's error message varies by version — Rule 22 version-variance exception applies
        expect { command.call('tree', 'HEAD:README.md') }.to raise_error(Git::FailedError)
      end
    end
  end
end
