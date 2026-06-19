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

    it 'uses execution context + command path' do
      stdout = <<~OUTPUT
        abc123\tHEAD
        abc123\trefs/heads/main
      OUTPUT

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
    let(:context) { instance_double(Git::ExecutionContext::Global) }
    let(:ls_remote_command) { instance_double(Git::Commands::LsRemote) }

    before do
      allow(Git::ExecutionContext::Global).to receive(:new).with(logger: nil).and_return(context)
      allow(Git::Commands::LsRemote).to receive(:new).with(context).and_return(ls_remote_command)
    end

    it 'uses the direct LsRemote + parser path' do
      stdout = "ref: refs/heads/main\tHEAD\nabc123\tHEAD\n"

      expect(ls_remote_command).to receive(:call)
        .with('origin', 'HEAD', symref: true).and_return(command_result(stdout))

      expect(described_class.default_branch('origin')).to eq('main')
    end

    it 'passes options[:log] to the execution context' do
      logger = instance_double(Logger)
      allow(Git::ExecutionContext::Global).to receive(:new).with(logger: logger).and_return(context)
      allow(ls_remote_command).to receive(:call).and_return(command_result("ref: refs/heads/main\tHEAD\n"))

      result = described_class.default_branch('origin', log: logger)

      expect(Git::ExecutionContext::Global).to have_received(:new).with(logger: logger)
      expect(result).to eq('main')
    end
  end
end
