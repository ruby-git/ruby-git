# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/write_tree'

RSpec.describe Git::Commands::WriteTree, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  before do
    # Stage a file so the index is non-empty and fully merged
    write_file('hello.txt', "hello\n")
    repo.add('hello.txt')
  end

  describe '#call' do
    context 'when the command succeeds' do
      it 'returns a CommandLineResult with the tree SHA on stdout' do
        result = command.call

        expect(result).to be_a(Git::CommandLineResult)
        expect(result.stdout).to match(/\A[0-9a-f]{40}\z/)
      end

      context 'with the :prefix option' do
        it 'writes a tree object for a subdirectory' do
          write_file('sub/file.txt', "content\n")
          repo.add('sub/file.txt')

          result = command.call(prefix: 'sub/')

          expect(result).to be_a(Git::CommandLineResult)
          expect(result.stdout).to match(/\A[0-9a-f]{40}\z/)
        end
      end
    end

    context 'when the command fails' do
      it 'raises FailedError with a nonexistent prefix' do
        # git's error message phrasing varies by version — anchor on the stable input value
        expect { command.call(prefix: 'nonexistent/') }
          .to raise_error(Git::FailedError, /nonexistent/)
      end
    end
  end
end
