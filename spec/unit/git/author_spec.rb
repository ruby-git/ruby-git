# frozen_string_literal: true

require 'spec_helper'
require 'git/author'

RSpec.describe Git::Author do
  describe '#initialize' do
    subject(:instance) { described_class.new(author_string) }

    let(:author_string) { 'John Doe <john.doe@example.com> 1627849923 +0200' }

    before do
      allow(Git::Deprecation).to receive(:warn)
    end

    context 'with a well-formed author string' do
      it 'emits a deprecation warning naming Git::AuthorInfo and still parses the string' do
        expect(instance).to have_attributes(
          name: 'John Doe',
          email: 'john.doe@example.com',
          date: Time.at(1_627_849_923)
        )
        expect(Git::Deprecation).to have_received(:warn).with(a_string_including('Git::AuthorInfo'))
      end
    end

    context 'with a string that does not match the author format' do
      let(:author_string) { 'not an author string' }

      it 'emits a deprecation warning naming Git::AuthorInfo and leaves the attributes nil' do
        expect(instance).to have_attributes(name: nil, email: nil, date: nil)
        expect(Git::Deprecation).to have_received(:warn).with(a_string_including('Git::AuthorInfo'))
      end
    end

    context 'when Git::Deprecation is unavailable (partial require)' do
      before { hide_const('Git::Deprecation') }

      it 'still parses the author string without raising' do
        expect(instance).to have_attributes(
          name: 'John Doe',
          email: 'john.doe@example.com',
          date: Time.at(1_627_849_923)
        )
      end
    end
  end
end
