# frozen_string_literal: true

require 'spec_helper'
require 'git/fsck_result'

RSpec.describe Git::FsckResult do
  # FsckResult stores arrays without calling any methods on the elements.
  # Plain objects are used as stand-ins; no FsckObject class is required here.
  let(:obj1) { Object.new }
  let(:obj2) { Object.new }
  let(:obj3) { Object.new }
  let(:obj4) { Object.new }
  let(:obj5) { Object.new }

  let(:described_instance) { described_class.new(exit_status: 0, stderr: '') }

  describe '#initialize' do
    context 'without keyword arguments' do
      subject(:instance) { described_class.new }

      it 'defaults all arrays to empty, exit_status to 0, and stderr to an empty string' do
        expect(instance).to have_attributes(
          dangling: [],
          missing: [],
          unreachable: [],
          warnings: [],
          errors: [],
          root: [],
          tagged: [],
          exit_status: 0,
          stderr: ''
        )
      end
    end

    context 'with provided values' do
      subject(:instance) do
        described_class.new(
          dangling: [obj1],
          missing: [obj2],
          unreachable: [obj3],
          warnings: [obj4],
          errors: [obj5],
          exit_status: 8,
          stderr: "error: refs/heads/broken: not a commit\n"
        )
      end

      it 'stores all provided values' do
        expect(instance).to have_attributes(
          dangling: [obj1],
          missing: [obj2],
          unreachable: [obj3],
          warnings: [obj4],
          errors: [obj5],
          exit_status: 8,
          stderr: "error: refs/heads/broken: not a commit\n"
        )
      end
    end
  end

  describe '#empty?' do
    subject(:result) { described_instance.empty? }

    context 'when all issue arrays are empty' do
      it { is_expected.to be true }
    end

    context 'when dangling is not empty' do
      let(:described_instance) { described_class.new(dangling: [obj1], exit_status: 0, stderr: '') }

      it { is_expected.to be false }
    end

    context 'when only root and tagged are non-empty' do
      let(:described_instance) { described_class.new(root: [obj1], tagged: [obj2], exit_status: 0, stderr: '') }

      it 'returns true because root and tagged are informational, not issues' do
        is_expected.to be true
      end
    end
  end

  describe '#any_issues?' do
    subject(:result) { described_instance.any_issues? }

    context 'when all arrays are empty' do
      it { is_expected.to be false }
    end

    context 'when missing is not empty' do
      let(:described_instance) { described_class.new(missing: [obj1], exit_status: 0, stderr: '') }

      it { is_expected.to be true }
    end

    context 'when errors is not empty' do
      let(:described_instance) { described_class.new(errors: [obj1], exit_status: 0, stderr: '') }

      it { is_expected.to be true }
    end
  end

  describe '#all_objects' do
    subject(:result) { described_instance.all_objects }

    context 'with objects in multiple issue categories' do
      let(:described_instance) do
        described_class.new(
          dangling: [obj1],
          missing: [obj2],
          unreachable: [obj3],
          warnings: [obj4],
          errors: [obj5],
          exit_status: 0,
          stderr: ''
        )
      end

      it 'combines dangling, missing, unreachable, warnings, and errors (but not root or tagged)' do
        expect(result).to contain_exactly(obj1, obj2, obj3, obj4, obj5)
      end
    end

    context 'when all arrays are empty' do
      it { is_expected.to be_empty }
    end
  end

  describe '#count' do
    subject(:result) { described_instance.count }

    context 'when all arrays are empty' do
      it { is_expected.to eq(0) }
    end

    context 'with objects spread across multiple categories' do
      let(:described_instance) do
        described_class.new(
          dangling: [obj1],
          missing: [obj2],
          unreachable: [],
          warnings: [obj3, obj4],
          errors: [obj5],
          exit_status: 0,
          stderr: ''
        )
      end

      it 'returns the total number of issue objects' do
        is_expected.to eq(5)
      end
    end
  end

  describe '#to_h' do
    subject(:result) { described_instance.to_h }

    context 'with some populated arrays' do
      let(:described_instance) { described_class.new(dangling: [obj1], missing: [obj2], exit_status: 0, stderr: '') }

      it 'returns a hash containing every collection' do
        expect(result).to eq(
          dangling: [obj1],
          missing: [obj2],
          unreachable: [],
          warnings: [],
          errors: [],
          root: [],
          tagged: []
        )
      end
    end

    context 'with an empty result' do
      it 'returns a hash with all collections empty' do
        expect(result.keys).to contain_exactly(:dangling, :missing, :unreachable, :warnings, :errors, :root, :tagged)
        expect(result.values).to all(be_empty)
      end
    end
  end
end
