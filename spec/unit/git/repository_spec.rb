# frozen_string_literal: true

require 'spec_helper'
require 'git/repository'

RSpec.describe Git::Repository do
  let(:execution_context) { instance_double(Git::ExecutionContext::Repository) }
  let(:described_instance) { described_class.new(execution_context: execution_context) }

  describe '#initialize' do
    subject { described_instance }

    it 'can be constructed with an execution_context:' do
      expect { described_class.new(execution_context: execution_context) }.not_to raise_error
    end

    it 'raises ArgumentError when execution_context: is missing' do
      expect { described_class.new }.to raise_error(ArgumentError)
    end

    it 'raises ArgumentError when execution_context: is nil' do
      expect do
        described_class.new(execution_context: nil)
      end.to raise_error(ArgumentError, /execution_context must not be nil/)
    end
  end
end
