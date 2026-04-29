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
end
