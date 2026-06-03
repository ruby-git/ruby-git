# frozen_string_literal: true

require 'spec_helper'
require 'git/repository'
require 'git/repository/inspecting'

# Integration-level coverage for Git::Repository::Inspecting#show is provided by
# the underlying command integration tests (spec/integration/git/commands/show_spec.rb),
# but #show performs facade-owned argument pre-processing (objectish/path joining)
# and #fsck performs facade-owned output parsing, so end-to-end behavior is also
# covered by spec/integration/git/repository/inspecting_spec.rb.

RSpec.describe Git::Repository::Inspecting do
  let(:execution_context) { instance_double(Git::ExecutionContext::Repository) }
  let(:described_instance) { Git::Repository.new(execution_context: execution_context) }

  describe '#show' do
    subject(:result) { described_instance.show }

    let(:show_command) { instance_double(Git::Commands::Show) }
    let(:show_result) { command_result("commit content\n") }

    before do
      allow(Git::Commands::Show).to receive(:new).with(execution_context).and_return(show_command)
    end

    context 'with no arguments' do
      it 'delegates to Git::Commands::Show#call with no object arguments' do
        expect(show_command).to receive(:call).with(no_args).and_return(show_result)
        result
      end

      it 'returns the command stdout' do
        allow(show_command).to receive(:call).with(no_args).and_return(show_result)
        expect(result).to eq("commit content\n")
      end
    end

    context 'with an objectish' do
      subject(:result) { described_instance.show('HEAD~1') }

      it 'delegates to Git::Commands::Show#call with the objectish' do
        expect(show_command).to receive(:call).with('HEAD~1').and_return(show_result)
        result
      end
    end

    context 'with an objectish and a path' do
      subject(:result) { described_instance.show('HEAD', 'README.md') }

      it 'joins the objectish and path with a colon' do
        expect(show_command).to receive(:call).with('HEAD:README.md').and_return(show_result)
        result
      end
    end

    context 'with only a path' do
      subject(:result) { described_instance.show(nil, 'README.md') }

      it 'defaults objectish to HEAD and joins with a colon' do
        expect(show_command).to receive(:call).with('HEAD:README.md').and_return(show_result)
        result
      end
    end
  end

  describe '#fsck' do
    subject(:result) { described_instance.fsck }

    let(:fsck_command) { instance_double(Git::Commands::Fsck) }
    let(:fsck_result) { command_result("dangling commit #{'a' * 40}\n") }
    let(:parsed_result) { instance_double(Git::FsckResult) }

    before do
      allow(Git::Commands::Fsck).to receive(:new).with(execution_context).and_return(fsck_command)
      allow(Git::Parsers::Fsck).to receive(:parse).and_return(parsed_result)
    end

    context 'with no arguments' do
      it 'delegates to Git::Commands::Fsck#call forcing no_progress' do
        expect(fsck_command).to receive(:call).with(no_progress: true).and_return(fsck_result)
        result
      end

      it 'parses the command stdout via Git::Parsers::Fsck' do
        allow(fsck_command).to receive(:call).and_return(fsck_result)
        expect(Git::Parsers::Fsck).to receive(:parse).with("dangling commit #{'a' * 40}\n")
        result
      end

      it 'returns the parsed FsckResult' do
        allow(fsck_command).to receive(:call).and_return(fsck_result)
        expect(result).to be(parsed_result)
      end
    end

    context 'with specific objects' do
      subject(:result) { described_instance.fsck('abc1234', 'def5678') }

      it 'forwards the objects to Git::Commands::Fsck#call' do
        expect(fsck_command).to(
          receive(:call).with('abc1234', 'def5678', no_progress: true).and_return(fsck_result)
        )
        result
      end
    end

    context 'with options' do
      subject(:result) { described_instance.fsck(strict: true, unreachable: true) }

      it 'forwards the options to Git::Commands::Fsck#call' do
        expect(fsck_command).to(
          receive(:call).with(no_progress: true, strict: true, unreachable: true).and_return(fsck_result)
        )
        result
      end
    end

    context 'with an unknown option' do
      subject(:result) { described_instance.fsck(bogus: true) }

      it 'raises ArgumentError' do
        expect { result }.to raise_error(ArgumentError, /Unknown options: bogus/)
      end

      it 'does not call Git::Commands::Fsck' do
        expect(fsck_command).not_to receive(:call)
        begin
          result
        rescue ArgumentError
          # expected
        end
      end
    end

    context 'when a caller tries to toggle progress' do
      it 'rejects :progress so suppression cannot be overridden' do
        expect { described_instance.fsck(progress: true) }.to(
          raise_error(ArgumentError, /Unknown options: progress/)
        )
      end

      it 'rejects :no_progress so suppression cannot be overridden' do
        expect { described_instance.fsck(no_progress: false) }.to(
          raise_error(ArgumentError, /Unknown options: no_progress/)
        )
      end
    end
  end
end
