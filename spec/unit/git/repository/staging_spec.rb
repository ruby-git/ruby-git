# frozen_string_literal: true

require 'spec_helper'
require 'git/repository'
require 'git/repository/staging'

# Integration-level coverage for Git::Repository::Staging is provided by the
# underlying command integration tests:
#   spec/integration/git/commands/add_spec.rb
#   spec/integration/git/commands/reset_spec.rb
# Both #add and #reset delegate to a single Git::Commands::* class with no
# multi-command orchestration or facade-owned post-processing of git output.
# The unit specs below cover the facade's own behavior (option whitelisting and
# negatable-flag normalization); the command integration specs cover end-to-end
# git execution. No facade integration spec is needed.

RSpec.describe Git::Repository::Staging do
  let(:execution_context) { instance_double(Git::ExecutionContext::Repository) }
  let(:described_instance) { Git::Repository.new(execution_context: execution_context) }

  describe '#add' do
    subject(:result) { described_instance.add }

    let(:add_command) { instance_double(Git::Commands::Add) }
    let(:add_result) { command_result('add output') }

    before do
      allow(Git::Commands::Add).to receive(:new).with(execution_context).and_return(add_command)
    end

    context 'with default arguments' do
      it 'delegates to Git::Commands::Add#call with the default path' do
        expect(add_command).to receive(:call).with('.').and_return(add_result)
        result
      end

      it 'returns the command stdout' do
        allow(add_command).to receive(:call).with('.').and_return(add_result)
        expect(result).to eq('add output')
      end
    end

    context 'with a single file path' do
      subject(:result) { described_instance.add('path/to/file.rb') }

      it 'delegates to Git::Commands::Add#call with the given path' do
        expect(add_command).to receive(:call).with('path/to/file.rb').and_return(add_result)
        result
      end
    end

    context 'with an array of paths' do
      subject(:result) { described_instance.add(['a.rb', 'b.rb']) }

      it 'splatted paths are forwarded as separate arguments' do
        expect(add_command).to receive(:call).with('a.rb', 'b.rb').and_return(add_result)
        result
      end
    end

    context 'with force: true' do
      subject(:result) { described_instance.add('file.rb', force: true) }

      it 'forwards force: true to Git::Commands::Add#call' do
        expect(add_command).to receive(:call).with('file.rb', force: true).and_return(add_result)
        result
      end
    end

    context 'with all: true' do
      subject(:result) { described_instance.add('file.rb', all: true) }

      it 'forwards all: true to Git::Commands::Add#call' do
        expect(add_command).to receive(:call).with('file.rb', all: true).and_return(add_result)
        result
      end

      it 'returns the command stdout' do
        allow(add_command).to receive(:call).with('file.rb', all: true).and_return(add_result)
        expect(result).to eq('add output')
      end
    end

    context 'with all: false' do
      subject(:result) { described_instance.add('file.rb', all: false) }

      it 'normalizes all: false away so --no-all is never emitted' do
        expect(add_command).to receive(:call).with('file.rb').and_return(add_result)
        result
      end
    end

    context 'with an unknown option' do
      subject(:result) { described_instance.add('file.rb', bogus: true) }

      it 'raises ArgumentError' do
        expect { result }.to raise_error(ArgumentError, /Unknown options: bogus/)
      end

      it 'does not call Git::Commands::Add' do
        expect(add_command).not_to receive(:call)
        begin
          result
        rescue ArgumentError
          # expected
        end
      end
    end
  end

  describe '#reset' do
    subject(:result) { described_instance.reset }

    let(:reset_command) { instance_double(Git::Commands::Reset) }
    let(:reset_result) { command_result('reset output') }

    before do
      allow(Git::Commands::Reset).to receive(:new).with(execution_context).and_return(reset_command)
    end

    context 'with no arguments' do
      it 'delegates to Git::Commands::Reset#call with nil commit' do
        expect(reset_command).to receive(:call).with(nil).and_return(reset_result)
        result
      end

      it 'returns the command stdout' do
        allow(reset_command).to receive(:call).with(nil).and_return(reset_result)
        expect(result).to eq('reset output')
      end
    end

    context 'with a commitish' do
      subject(:result) { described_instance.reset('HEAD~1') }

      it 'delegates to Git::Commands::Reset#call with the given commitish' do
        expect(reset_command).to receive(:call).with('HEAD~1').and_return(reset_result)
        result
      end
    end

    context 'with options' do
      subject(:result) { described_instance.reset('HEAD~1', hard: true) }

      it 'forwards options to Git::Commands::Reset#call' do
        expect(reset_command).to receive(:call).with('HEAD~1', hard: true).and_return(reset_result)
        result
      end
    end

    context 'with an unknown option' do
      subject(:result) { described_instance.reset('HEAD~1', bogus: true) }

      it 'raises ArgumentError' do
        expect { result }.to raise_error(ArgumentError, /Unknown options: bogus/)
      end
    end
  end
end
