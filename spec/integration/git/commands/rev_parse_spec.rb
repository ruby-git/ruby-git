# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/rev_parse'

RSpec.describe Git::Commands::RevParse, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  before do
    write_file('file.txt', "content\n")
    repo.add('file.txt')
    repo.commit('Initial commit')
  end

  describe '#call' do
    context 'when the command succeeds' do
      it 'returns a Git::CommandLine::Result for --verify HEAD' do
        result = command.call('HEAD', verify: true)

        expect(result).to be_a(Git::CommandLine::Result)
        expect(result.stdout).not_to be_empty
      end

      # These examples pin the --verify outputs that Git::Repository::Stashing
      # relies on when it resolves a commit before `git stash store`.
      it 'peels an annotated tag to the tagged commit with a ^{commit} suffix' do
        head = repo.rev_parse('HEAD')
        repo.tag_create('v1', 'HEAD', message: 'annotated')

        result = command.call('v1^{commit}', verify: true)

        expect(result.stdout.strip).to eq(head)
        expect(repo.rev_parse('v1')).not_to eq(head)
      end

      it 'prints a negated revision back with its caret instead of failing' do
        head = repo.rev_parse('HEAD')

        result = command.call('^HEAD^{commit}', verify: true)

        expect(result.stdout.strip).to eq("^#{head}")
      end

      it 'echoes a well-formed object id that names no object when there is no suffix' do
        missing = 'a' * 40

        result = command.call(missing, verify: true)

        expect(result.stdout.strip).to eq(missing)
      end

      it 'resolves a :/<text> search to the commit whose message matches' do
        head = repo.rev_parse('HEAD')

        result = command.call(':/Initial commit', verify: true)

        expect(result.stdout.strip).to eq(head)
      end
    end

    context 'when the command fails' do
      it 'raises FailedError for a nonexistent ref with --verify' do
        # git's error message phrasing varies by version — anchor on the stable input value
        expect { command.call('nonexistent-ref', verify: true) }
          .to raise_error(Git::FailedError, /nonexistent-ref/)
      end

      it 'raises FailedError for a well-formed object id that names no object with a ^{commit} suffix' do
        missing = 'a' * 40

        expect { command.call("#{missing}^{commit}", verify: true) }.to raise_error(Git::FailedError, /#{missing}/)
      end

      it 'raises FailedError for a :/<text> search with a ^{commit} suffix' do
        expect { command.call(':/Initial commit^{commit}', verify: true) }
          .to raise_error(Git::FailedError, /Initial commit/)
      end

      it 'raises FailedError for a range with --verify' do
        expect { command.call('HEAD..HEAD', verify: true) }.to raise_error(Git::FailedError, /HEAD\.\.HEAD/)
      end
    end
  end
end
