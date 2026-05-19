# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Git::Base do
  describe '#binary_path' do
    context 'when not specified' do
      subject(:base) { described_class.new }

      it 'defaults to :use_global_config' do
        expect(base.binary_path).to eq(:use_global_config)
      end
    end

    context 'when an explicit path is provided' do
      subject(:base) { described_class.new(binary_path: '/custom/git') }

      it 'returns the provided path' do
        expect(base.binary_path).to eq('/custom/git')
      end
    end

    context 'when binary_path is explicitly nil' do
      it 'raises ArgumentError' do
        expect { described_class.new(binary_path: nil) }.to raise_error(ArgumentError, /binary_path/)
      end
    end
  end

  describe '#full_log_commits' do
    subject(:result) { described_instance.full_log_commits(opts) }

    let(:described_instance) { described_class.new }
    let(:opts) { { count: 3 } }
    let(:facade_repository) { instance_double(Git::Repository) }
    let(:log_data) { [{ 'sha' => 'abc123' }] }

    before do
      allow(described_instance).to receive(:facade_repository).and_return(facade_repository)
    end

    it 'delegates to facade_repository with opts and returns the facade result' do
      expect(facade_repository).to receive(:full_log_commits).with(opts).and_return(log_data)
      expect(result).to eq(log_data)
    end
  end
end
