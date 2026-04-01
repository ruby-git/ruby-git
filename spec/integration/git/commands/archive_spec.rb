# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/archive'

RSpec.describe Git::Commands::Archive, :integration do
  include_context 'in an empty repository'

  subject(:command) { described_class.new(execution_context) }

  before do
    write_file('file.txt', "content\n")
    repo.add('file.txt')
    repo.commit('Initial commit')
  end

  describe '#call' do
    context 'when the command succeeds' do
      it 'captures binary-identical archive content in stdout' do
        # Stream to a file for the reference bytes
        streamed_bytes = Tempfile.create(%w[archive .tar]) do |f|
          f.binmode
          command.call('HEAD', format: 'tar', out: f)
          f.flush
          f.rewind
          f.read
        end

        # Capture in-memory and compare byte-for-byte
        result = command.call('HEAD', format: 'tar')

        expect(result).to be_a(Git::CommandLineResult)
        expect(result.stdout).to eq(streamed_bytes)
      end

      it 'streams output to a file when out: is given' do
        Tempfile.create(%w[archive .tar]) do |f|
          f.binmode
          result = command.call('HEAD', format: 'tar', out: f)
          f.flush
          expect(f.size).to be > 0
          expect(result.stdout).to eq('')
        end
      end
    end

    context 'when the command fails' do
      it 'raises FailedError for a nonexistent tree-ish' do
        # git's error message phrasing varies by version — anchor on the stable input value
        expect { command.call('nonexistent-ref', format: 'tar') }
          .to raise_error(Git::FailedError, /nonexistent-ref/)
      end
    end
  end
end
