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

  describe '#log' do
    subject(:result) { described_instance.log(count) }

    let(:described_instance) { described_class.new }
    let(:count) { 5 }
    let(:facade_repository) { instance_double(Git::Repository) }
    let(:log_instance) { instance_double(Git::Log) }

    before do
      allow(described_instance).to receive(:facade_repository).and_return(facade_repository)
      allow(facade_repository).to receive(:log).with(count).and_return(log_instance)
    end

    it 'delegates to facade_repository.log with count and returns the result' do
      expect(facade_repository).to receive(:log).with(count).and_return(log_instance)
      expect(result).to be(log_instance)
    end

    context 'with default count' do
      subject(:result) { described_instance.log }

      before do
        allow(facade_repository).to receive(:log).with(30).and_return(log_instance)
      end

      it 'passes 30 as the default count' do
        expect(facade_repository).to receive(:log).with(30).and_return(log_instance)
        expect(result).to be(log_instance)
      end
    end
  end

  describe '#diff_stats' do
    subject(:result) { described_instance.diff_stats(objectish, obj2, opts) }

    let(:described_instance) { described_class.new }
    let(:objectish) { 'HEAD~1' }
    let(:obj2) { 'HEAD' }
    let(:opts) { { path_limiter: 'lib/' } }
    let(:facade_repository) { instance_double(Git::Repository) }
    let(:diff_stats_result) { instance_double(Git::DiffStats) }

    before do
      allow(described_instance).to receive(:facade_repository).and_return(facade_repository)
    end

    it 'delegates to facade_repository.diff_stats with all arguments' do
      expect(facade_repository).to receive(:diff_stats).with(objectish, obj2, opts).and_return(diff_stats_result)
      expect(result).to be(diff_stats_result)
    end
  end
end
