# frozen_string_literal: true

require 'spec_helper'
require 'git/repository'
require 'git/repository/maintenance'

RSpec.describe Git::Repository::Maintenance do
  let(:execution_context) { instance_double(Git::ExecutionContext::Repository) }
  let(:described_instance) { Git::Repository.new(execution_context: execution_context) }

  describe '#repack' do
    subject(:result) { described_instance.repack }

    let(:repack_command) { instance_double(Git::Commands::Repack) }
    let(:repack_result) { command_result('') }

    before do
      allow(Git::Commands::Repack).to receive(:new).with(execution_context).and_return(repack_command)
    end

    it 'delegates to Git::Commands::Repack#call with a: true, d: true' do
      expect(repack_command).to receive(:call).with(a: true, d: true).and_return(repack_result)
      result
    end

    it 'returns the command stdout as a String' do
      allow(repack_command).to receive(:call).with(a: true, d: true).and_return(repack_result)
      expect(result).to eq('')
    end
  end

  describe '#gc' do
    subject(:result) { described_instance.gc }

    let(:gc_command) { instance_double(Git::Commands::Gc) }
    let(:gc_result) { command_result("Counting objects: 450, done.\n") }

    before do
      allow(Git::Commands::Gc).to receive(:new).with(execution_context).and_return(gc_command)
    end

    it 'delegates to Git::Commands::Gc#call with prune: true, aggressive: true, auto: true' do
      expect(gc_command).to receive(:call).with(prune: true, aggressive: true, auto: true).and_return(gc_result)
      result
    end

    it 'returns the command stdout as a String' do
      allow(gc_command).to receive(:call).with(prune: true, aggressive: true, auto: true).and_return(gc_result)
      expect(result).to eq("Counting objects: 450, done.\n")
    end
  end
end
