# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Git do
  describe '.ls_remote' do
    let(:context) { instance_double(Git::ExecutionContext::Global) }
    let(:ls_remote_command) { instance_double(Git::Commands::LsRemote) }

    before do
      allow(Git::ExecutionContext::Global).to receive(:new).with(logger: nil).and_return(context)
      allow(Git::Commands::LsRemote).to receive(:new).with(context).and_return(ls_remote_command)
    end

    it 'uses execution context + command path (not Git::Lib)' do
      stdout = <<~OUTPUT
        abc123\tHEAD
        abc123\trefs/heads/main
      OUTPUT

      expect(Git::Lib).not_to receive(:new)
      expect(ls_remote_command).to receive(:call).with('.', tags: true).and_return(command_result(stdout))

      expect(described_class.ls_remote(nil, tags: true)).to eq(
        'head' => { ref: 'HEAD', sha: 'abc123' },
        'branches' => { 'main' => { ref: 'refs', sha: 'abc123' } }
      )
    end

    it 'passes options[:log] to the execution context and not to command options' do
      logger = instance_double(Logger)
      allow(Git::ExecutionContext::Global).to receive(:new).with(logger: logger).and_return(context)
      allow(ls_remote_command).to receive(:call).and_return(command_result("abc123\tHEAD\n"))

      described_class.ls_remote('origin', log: logger)

      expect(Git::ExecutionContext::Global).to have_received(:new).with(logger: logger)
      expect(ls_remote_command).to have_received(:call).with('origin')
    end

    context 'with a parser-incompatible option' do
      it 'raises ArgumentError for :get_url' do
        expect { described_class.ls_remote('origin', get_url: true) }.to raise_error(
          ArgumentError,
          /Unknown options: get_url/
        )
      end

      it 'raises ArgumentError for :symref' do
        expect { described_class.ls_remote('origin', symref: true) }.to raise_error(
          ArgumentError,
          /Unknown options: symref/
        )
      end
    end
  end

  describe '.default_branch' do
    it 'delegates to Git::Base.repository_default_branch preserving options' do
      logger = instance_double(Logger)

      expect(Git::Base).to receive(:repository_default_branch)
        .with('origin', { log: logger })
        .and_return('main')

      expect(described_class.default_branch('origin', log: logger)).to eq('main')
    end
  end
end
