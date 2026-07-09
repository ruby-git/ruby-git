# frozen_string_literal: true

require 'spec_helper'
require 'git/commands/init'

require 'git/execution_context/global'

RSpec.describe Git::Commands::Init, :integration do
  # Init creates new repositories, so it uses an unbound execution context
  # (no pre-existing repo), matching how Git.init calls it in production.
  subject(:command) { described_class.new(execution_context) }

  let(:execution_context) { Git::ExecutionContext::Global.new }
  let(:init_dir) { Dir.mktmpdir }

  after { FileUtils.rm_rf(init_dir) }

  describe '#call' do
    describe 'when the command succeeds' do
      it 'returns a CommandLineResult' do
        result = command.call(init_dir)

        expect(result).to be_a(Git::CommandLine::Result)
      end

      context 'with bare option' do
        it 'returns a CommandLineResult' do
          result = command.call(init_dir, bare: true)

          expect(result).to be_a(Git::CommandLine::Result)
        end
      end
    end

    describe 'when the command fails' do
      it 'raises FailedError when the path is a file' do
        file_path = File.join(init_dir, 'not-a-directory')
        File.write(file_path, 'content')

        expect { command.call(file_path) }.to raise_error(Git::FailedError)
      end
    end
  end
end
