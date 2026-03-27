# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/show_ref/list'

RSpec.describe Git::Commands::ShowRef::List, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  before do
    write_file('file.txt', "content\n")
    repo.add('.')
    repo.commit('Initial commit')
    repo.add_tag('v1.0')
  end

  describe '#call' do
    context 'when the command succeeds' do
      it 'returns a CommandLineResult' do
        result = command.call

        expect(result).to be_a(Git::CommandLineResult)
      end

      it 'returns exit status 0 when refs are found' do
        result = command.call

        expect(result.status.exitstatus).to eq(0)
      end

      it 'returns exit status 1 when no refs match the pattern' do
        result = command.call('nonexistent-ref-xyz')

        expect(result.status.exitstatus).to eq(1)
      end

      it 'returns exit status 0 with the :tags option' do
        result = command.call(tags: true)

        expect(result.status.exitstatus).to eq(0)
      end

      it 'returns exit status 0 with the :heads option' do
        result = command.call(heads: true)

        expect(result.status.exitstatus).to eq(0)
      end

      it 'returns exit status 0 with the :head option' do
        result = command.call(head: true)

        expect(result.status.exitstatus).to eq(0)
      end

      it 'returns exit status 0 with the :dereference option' do
        repo.add_tag('v1.0-annotated', annotate: true, message: 'annotation')

        result = command.call(dereference: true)

        expect(result.status.exitstatus).to eq(0)
      end
    end

    context 'when the command fails' do
      before { FileUtils.rm_rf(File.join(repo_dir, '.git')) }

      it 'raises Git::FailedError' do
        expect { command.call }.to raise_error(Git::FailedError, /git repository/)
      end
    end
  end
end
