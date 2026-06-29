# frozen_string_literal: true

require 'spec_helper'
require 'git/errors'

RSpec.describe Git::CommandLineError do
  # A minimal stand-in for ProcessExecuter::Result whose only contract here is
  # responding to #to_s. Using a stub_const-style object keeps the test isolated
  # from ProcessExecuter and Process::Status semantics.
  let(:status) do
    Class.new do
      def to_s = 'pid 89784 exit 1'
    end.new
  end

  let(:result) do
    Git::CommandLineResult.new(%w[git status], status, 'stdout', 'stderr')
  end

  let(:described_instance) { described_class.new(result) }

  describe '#initialize' do
    subject(:instance) { described_instance }

    it 'stores the result' do
      expect(instance).to have_attributes(result: result)
    end
  end

  describe '#to_s' do
    subject(:message) { described_instance.to_s }

    it 'includes the command, status, and inspected stderr' do
      expect(message).to eq('["git", "status"], status: pid 89784 exit 1, stderr: "stderr"')
    end
  end
end
