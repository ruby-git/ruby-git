# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Git::AuthorInfo do
  describe '#initialize' do
    subject(:instance) { described_class.new(name: name, email: email, date: date) }

    let(:name) { 'John Doe' }
    let(:email) { 'john.doe@example.com' }
    let(:date) { Time.at(1_627_849_923) }

    it 'stores all constructor arguments' do
      expect(instance).to have_attributes(name: name, email: email, date: date)
    end

    it 'creates an immutable object' do
      expect(instance).to be_frozen
      expect { instance.name = 'Jane Doe' }.to raise_error(NoMethodError, /name=/)
    end

    it 'compares equal to another instance with the same values' do
      expect(instance).to eq(described_class.new(name: name, email: email, date: date))
    end
  end

  describe '.parse' do
    subject(:result) { described_class.parse(author_string) }

    let(:author_string) { 'John Doe <john.doe@example.com> 1627849923 +0200' }

    context 'with a well-formed author string' do
      it 'returns a Git::AuthorInfo with the parsed name, email, and date' do
        expect(result).to be_a(described_class)
        expect(result).to have_attributes(
          name: 'John Doe',
          email: 'john.doe@example.com',
          date: Time.at(1_627_849_923)
        )
      end
    end

    context 'with a string that does not match the author format' do
      let(:author_string) { 'not an author string' }

      it 'returns a Git::AuthorInfo with nil name, email, and date' do
        expect(result).to be_a(described_class)
        expect(result).to have_attributes(name: nil, email: nil, date: nil)
      end
    end
  end
end
