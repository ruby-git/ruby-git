# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Git::VersionConstraint do
  describe 'instantiation' do
    it 'creates a VersionConstraint with min and before' do
      constraint = described_class.new(
        min: Git::Version.parse('2.28.0'),
        before: Git::Version.parse('2.50.0')
      )
      expect(constraint.min).to eq(Git::Version.parse('2.28.0'))
      expect(constraint.before).to eq(Git::Version.parse('2.50.0'))
    end

    it 'defaults before to nil when omitted' do
      constraint = described_class.new(min: Git::Version.parse('2.28.0'))
      expect(constraint.min).to eq(Git::Version.parse('2.28.0'))
      expect(constraint.before).to be_nil
    end

    it 'defaults min to nil when omitted' do
      constraint = described_class.new(before: Git::Version.parse('2.50.0'))
      expect(constraint.min).to be_nil
      expect(constraint.before).to eq(Git::Version.parse('2.50.0'))
    end
  end

  describe '#too_old?' do
    context 'when min is nil' do
      let(:constraint) { described_class.new(before: Git::Version.parse('2.50.0')) }

      it 'returns false for any version' do
        expect(constraint.too_old?(Git::Version.parse('2.0.0'))).to be false
        expect(constraint.too_old?(Git::Version.parse('2.50.0'))).to be false
      end
    end

    context 'when min is set' do
      let(:constraint) { described_class.new(min: Git::Version.parse('2.28.0')) }

      it 'returns true for versions below min' do
        expect(constraint.too_old?(Git::Version.parse('2.27.0'))).to be true
        expect(constraint.too_old?(Git::Version.parse('2.0.0'))).to be true
      end

      it 'returns false for versions at or above min' do
        expect(constraint.too_old?(Git::Version.parse('2.28.0'))).to be false
        expect(constraint.too_old?(Git::Version.parse('2.30.0'))).to be false
      end
    end
  end

  describe '#too_new?' do
    context 'when before is nil' do
      let(:constraint) { described_class.new(min: Git::Version.parse('2.28.0')) }

      it 'returns false for any version' do
        expect(constraint.too_new?(Git::Version.parse('99.0.0'))).to be false
      end
    end

    context 'when before is set' do
      let(:constraint) { described_class.new(before: Git::Version.parse('2.50.0')) }

      it 'returns true for versions at or above before' do
        expect(constraint.too_new?(Git::Version.parse('2.50.0'))).to be true
        expect(constraint.too_new?(Git::Version.parse('2.51.0'))).to be true
      end

      it 'returns false for versions below before' do
        expect(constraint.too_new?(Git::Version.parse('2.49.0'))).to be false
        expect(constraint.too_new?(Git::Version.parse('2.28.0'))).to be false
      end
    end
  end

  describe '#satisfied_by?' do
    context 'with min only' do
      let(:constraint) { described_class.new(min: Git::Version.parse('2.28.0')) }

      it 'returns true when version meets minimum' do
        expect(constraint.satisfied_by?(Git::Version.parse('2.28.0'))).to be true
        expect(constraint.satisfied_by?(Git::Version.parse('3.0.0'))).to be true
      end

      it 'returns false when version is below minimum' do
        expect(constraint.satisfied_by?(Git::Version.parse('2.27.0'))).to be false
      end
    end

    context 'with before only' do
      let(:constraint) { described_class.new(before: Git::Version.parse('2.50.0')) }

      it 'returns true when version is below before' do
        expect(constraint.satisfied_by?(Git::Version.parse('2.49.0'))).to be true
        expect(constraint.satisfied_by?(Git::Version.parse('2.0.0'))).to be true
      end

      it 'returns false when version is at or above before' do
        expect(constraint.satisfied_by?(Git::Version.parse('2.50.0'))).to be false
        expect(constraint.satisfied_by?(Git::Version.parse('2.51.0'))).to be false
      end
    end

    context 'with both min and before' do
      let(:constraint) do
        described_class.new(
          min: Git::Version.parse('2.28.0'),
          before: Git::Version.parse('2.50.0')
        )
      end

      it 'returns true when version is in valid range' do
        expect(constraint.satisfied_by?(Git::Version.parse('2.28.0'))).to be true
        expect(constraint.satisfied_by?(Git::Version.parse('2.40.0'))).to be true
        expect(constraint.satisfied_by?(Git::Version.parse('2.49.9'))).to be true
      end

      it 'returns false when version is below min' do
        expect(constraint.satisfied_by?(Git::Version.parse('2.27.0'))).to be false
      end

      it 'returns false when version is at or above before' do
        expect(constraint.satisfied_by?(Git::Version.parse('2.50.0'))).to be false
        expect(constraint.satisfied_by?(Git::Version.parse('3.0.0'))).to be false
      end
    end
  end

  describe '#to_s' do
    context 'with min only' do
      it 'formats as a lower-bound requirement' do
        constraint = described_class.new(min: Git::Version.parse('2.28.0'))
        expect(constraint.to_s).to eq('>= 2.28.0')
      end
    end

    context 'with before only' do
      it 'formats as an upper-bound requirement' do
        constraint = described_class.new(before: Git::Version.parse('2.50.0'))
        expect(constraint.to_s).to eq('< 2.50.0')
      end
    end

    context 'with both min and before' do
      it 'formats as a bounded range requirement' do
        constraint = described_class.new(
          min: Git::Version.parse('2.28.0'),
          before: Git::Version.parse('2.50.0')
        )
        expect(constraint.to_s).to eq('>= 2.28.0, < 2.50.0')
      end
    end

    context 'with neither min nor before' do
      it 'formats as any version' do
        constraint = described_class.new(min: nil, before: nil)
        expect(constraint.to_s).to eq('any version')
      end
    end
  end

  describe 'equality' do
    it 'considers two constraints equal if min and before match' do
      c1 = described_class.new(min: Git::Version.parse('2.28.0'), before: Git::Version.parse('2.50.0'))
      c2 = described_class.new(min: Git::Version.parse('2.28.0'), before: Git::Version.parse('2.50.0'))
      expect(c1).to eq(c2)
    end

    it 'considers two constraints different if min differs' do
      c1 = described_class.new(min: Git::Version.parse('2.28.0'))
      c2 = described_class.new(min: Git::Version.parse('2.29.0'))
      expect(c1).not_to eq(c2)
    end

    it 'considers two constraints different if before differs' do
      c1 = described_class.new(before: Git::Version.parse('2.50.0'))
      c2 = described_class.new(before: Git::Version.parse('2.51.0'))
      expect(c1).not_to eq(c2)
    end
  end
end
