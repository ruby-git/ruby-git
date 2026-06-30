# frozen_string_literal: true

require 'spec_helper'
require 'git/status'
require 'git/repository'

RSpec.describe Git::Status do
  subject(:status) { described_class.new(base) }

  let(:base) { instance_double(Git::Repository) }
  let(:status_file) { instance_double(Git::Status::StatusFile, type: 'M', untracked: nil) }
  let(:files) { { 'file.rb' => status_file } }
  let(:factory) { instance_double(Git::Status::StatusFileFactory, construct_files: files) }

  before do
    allow(Git::Status::StatusFileFactory).to receive(:new).with(base).and_return(factory)
  end

  describe '#changed?' do
    context 'when core.ignoreCase is true' do
      before do
        allow(base).to receive(:config_get).with('core.ignoreCase').and_return(double(value: 'true'))
      end

      it 'finds a file using a different-cased path' do
        expect(status.changed?('FILE.RB')).to be(true)
      end

      it 'memoizes the config_get result across multiple calls' do
        expect(base).to receive(:config_get).with('core.ignoreCase').once.and_return(double(value: 'true'))

        status.changed?('FILE.RB')
        status.changed?('FILE.RB')
      end
    end

    context 'when core.ignoreCase is absent' do
      before do
        allow(base).to receive(:config_get).with('core.ignoreCase').and_return(nil)
      end

      it 'does not find a file with a different-cased path' do
        expect(status.changed?('FILE.RB')).to be(false)
      end

      it 'finds a file with the exact path' do
        expect(status.changed?('file.rb')).to be(true)
      end
    end
  end

  describe '#added?' do
    let(:status_file) { instance_double(Git::Status::StatusFile, type: 'A', untracked: nil) }

    context 'when core.ignoreCase is true' do
      before do
        allow(base).to receive(:config_get).with('core.ignoreCase').and_return(double(value: 'true'))
      end

      it 'finds a file using a different-cased path' do
        expect(status.added?('FILE.RB')).to be(true)
      end
    end

    context 'when core.ignoreCase is absent' do
      before do
        allow(base).to receive(:config_get).with('core.ignoreCase').and_return(nil)
      end

      it 'does not find a file with a different-cased path' do
        expect(status.added?('FILE.RB')).to be(false)
      end

      it 'finds a file with the exact path' do
        expect(status.added?('file.rb')).to be(true)
      end
    end
  end

  describe '#deleted?' do
    let(:status_file) { instance_double(Git::Status::StatusFile, type: 'D', untracked: nil) }

    context 'when core.ignoreCase is true' do
      before do
        allow(base).to receive(:config_get).with('core.ignoreCase').and_return(double(value: 'true'))
      end

      it 'finds a file using a different-cased path' do
        expect(status.deleted?('FILE.RB')).to be(true)
      end
    end

    context 'when core.ignoreCase is absent' do
      before do
        allow(base).to receive(:config_get).with('core.ignoreCase').and_return(nil)
      end

      it 'does not find a file with a different-cased path' do
        expect(status.deleted?('FILE.RB')).to be(false)
      end

      it 'finds a file with the exact path' do
        expect(status.deleted?('file.rb')).to be(true)
      end
    end
  end

  describe '#untracked?' do
    let(:status_file) { instance_double(Git::Status::StatusFile, type: nil, untracked: true) }

    context 'when core.ignoreCase is true' do
      before do
        allow(base).to receive(:config_get).with('core.ignoreCase').and_return(double(value: 'true'))
      end

      it 'finds a file using a different-cased path' do
        expect(status.untracked?('FILE.RB')).to be(true)
      end
    end

    context 'when core.ignoreCase is absent' do
      before do
        allow(base).to receive(:config_get).with('core.ignoreCase').and_return(nil)
      end

      it 'does not find a file with a different-cased path' do
        expect(status.untracked?('FILE.RB')).to be(false)
      end

      it 'finds a file with the exact path' do
        expect(status.untracked?('file.rb')).to be(true)
      end
    end
  end
end
