# frozen_string_literal: true

require 'spec_helper'
require 'pathname'
require 'git/log'
require 'git/repository'
require 'git/repository/logging'

# Integration-level coverage for Git::Repository::Logging is provided by:
#   spec/integration/git/repository/logging_spec.rb
# The unit specs below cover facade-owned option validation, argument shaping,
# unborn-branch handling, and parser edge cases.

RSpec.describe Git::Repository::Logging do
  let(:execution_context) { instance_double(Git::ExecutionContext::Repository) }
  let(:described_instance) { Git::Repository.new(execution_context: execution_context) }

  describe '#full_log_commits' do
    subject(:result) { described_instance.full_log_commits(opts) }

    let(:opts) { {} }
    let(:log_command) { instance_double(Git::Commands::Log) }

    before do
      allow(Git::Commands::Log).to receive(:new).with(execution_context).and_return(log_command)
    end

    context 'with no options' do
      let(:raw_output) do
        <<~RAW
          commit aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
          tree tttttttttttttttttttttttttttttttttttttttt
          parent pppppppppppppppppppppppppppppppppppppppp
          author A <a@example.com> 1 +0000
          committer A <a@example.com> 1 +0000

              first message
          commit bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
          tree uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu
          author B <b@example.com> 2 +0000
          committer B <b@example.com> 2 +0000

              second message
        RAW
      end

      it 'calls the command with parser-contract options and returns parsed commits' do
        expect(log_command).to receive(:call).with(no_color: true, pretty: 'raw').and_return(command_result(raw_output))

        expect(result).to eq(
          [
            {
              'sha' => 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
              'tree' => 'tttttttttttttttttttttttttttttttttttttttt',
              'parent' => ['pppppppppppppppppppppppppppppppppppppppp'],
              'author' => 'A <a@example.com> 1 +0000',
              'committer' => 'A <a@example.com> 1 +0000',
              'message' => "first message\n"
            },
            {
              'sha' => 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
              'tree' => 'uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu',
              'parent' => [],
              'author' => 'B <b@example.com> 2 +0000',
              'committer' => 'B <b@example.com> 2 +0000',
              'message' => "second message\n"
            }
          ]
        )
      end
    end

    context 'with a signed commit that includes multiline gpgsig metadata' do
      let(:expected_gpgsig) do
        <<~SIG.chomp
          -----BEGIN PGP SIGNATURE-----
          iQIzBAABCAAdFiEEXAMPLEKEYLINEONE
          =ABCD
          -----END PGP SIGNATURE-----
        SIG
      end

      let(:raw_output) do
        <<~RAW
          commit cccccccccccccccccccccccccccccccccccccccc
          tree tttttttttttttttttttttttttttttttttttttttt
          author C <c@example.com> 3 +0000
          committer C <c@example.com> 3 +0000
          gpgsig -----BEGIN PGP SIGNATURE-----
           iQIzBAABCAAdFiEEXAMPLEKEYLINEONE
           =ABCD
           -----END PGP SIGNATURE-----

              signed commit message
        RAW
      end

      it 'folds gpgsig continuation lines into a single gpgsig field' do
        allow(log_command).to receive(:call).with(no_color: true, pretty: 'raw').and_return(command_result(raw_output))

        expect(result).to eq(
          [
            {
              'sha' => 'cccccccccccccccccccccccccccccccccccccccc',
              'tree' => 'tttttttttttttttttttttttttttttttttttttttt',
              'parent' => [],
              'author' => 'C <c@example.com> 3 +0000',
              'committer' => 'C <c@example.com> 3 +0000',
              'gpgsig' => expected_gpgsig,
              'message' => "signed commit message\n"
            }
          ]
        )
      end
    end

    context 'with a commit that has an empty message' do
      let(:raw_output) do
        <<~RAW
          commit aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
          tree tttttttttttttttttttttttttttttttttttttttt
          parent bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
          author A <a@example.com> 2 +0000
          committer A <a@example.com> 2 +0000

          commit bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
          tree uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu
          author A <a@example.com> 1 +0000
          committer A <a@example.com> 1 +0000

              first message
        RAW
      end

      it 'preserves the empty message as an empty string' do
        allow(log_command).to receive(:call).with(no_color: true, pretty: 'raw').and_return(command_result(raw_output))

        expect(result.map { |commit| commit['message'] }).to eq(['', "first message\n"])
      end
    end

    context 'with all documented options and a between revision range' do
      let(:opts) do
        {
          count: 2,
          all: true,
          cherry: true,
          since: '2024-01-01',
          until: '2024-01-31',
          grep: 'fix',
          author: 'Jane',
          between: %w[v1.0.0 HEAD],
          path_limiter: Pathname('README.md'),
          skip: 1,
          merges: true
        }
      end

      it 'forwards mapped options and normalizes path_limiter to an array' do
        expect(log_command).to receive(:call).with(
          'v1.0.0..HEAD',
          no_color: true,
          pretty: 'raw',
          all: true,
          cherry: true,
          since: '2024-01-01',
          until: '2024-01-31',
          grep: 'fix',
          author: 'Jane',
          max_count: 2,
          path: [Pathname('README.md')],
          skip: 1,
          merges: true
        ).and_return(command_result(''))

        expect(result).to eq([])
      end
    end

    context 'with object as a String' do
      let(:opts) { { object: 'main~2..main' } }

      it 'passes object as the positional revision range argument' do
        expect(log_command).to receive(:call).with('main~2..main', no_color: true, pretty: 'raw').and_return(
          command_result('')
        )

        expect(result).to eq([])
      end
    end

    context 'with both between and object' do
      let(:opts) { { between: %w[v1.0.0 HEAD], object: 'ignored' } }

      it 'uses between and ignores object' do
        expect(log_command).to receive(:call).with('v1.0.0..HEAD', no_color: true, pretty: 'raw').and_return(
          command_result('')
        )

        expect(result).to eq([])
      end
    end

    context 'with object as a non-String' do
      let(:opts) { { object: :head } }

      it 'does not pass a positional revision range argument' do
        expect(log_command).to receive(:call).with(no_color: true, pretty: 'raw').and_return(command_result(''))

        expect(result).to eq([])
      end
    end

    context 'when git reports an unborn branch' do
      it 'returns an empty array for exit status 128 with the unborn-repository message' do
        failed_result = command_result('',
                                       stderr: "fatal: your current branch 'main' does not have any commits yet",
                                       exitstatus: 128)
        allow(log_command).to receive(:call).and_raise(Git::FailedError, failed_result)

        expect(result).to eq([])
      end
    end

    context 'when git fails for another reason with exit status 128' do
      it 're-raises Git::FailedError' do
        failed_result = command_result('', stderr: 'fatal: bad default revision', exitstatus: 128)
        allow(log_command).to receive(:call).and_raise(Git::FailedError, failed_result)

        expect { result }.to raise_error(Git::FailedError, /bad default revision/)
      end
    end

    context 'when git reports the unborn message with a non-128 exit status' do
      it 're-raises Git::FailedError' do
        failed_result = command_result('', stderr: 'fatal: does not have any commits yet', exitstatus: 1)
        allow(log_command).to receive(:call).and_raise(Git::FailedError, failed_result)

        expect { result }.to raise_error(Git::FailedError, /does not have any commits yet/)
      end
    end

    context 'option whitelisting' do
      context 'with unknown options' do
        let(:opts) { { bogus: true } }

        it 'raises ArgumentError for an unknown option key' do
          expect { result }.to raise_error(ArgumentError, /Unknown options: bogus/)
        end
      end
    end

    context 'input validation' do
      context 'with between as a non-array' do
        let(:opts) { { between: 'main..HEAD' } }

        it 'raises ArgumentError with an explanatory message' do
          expect { result }.to raise_error(
            ArgumentError,
            /must be an Array with exactly two non-nil values but was "main\.\.HEAD"/
          )
        end
      end

      context 'with between as an array of the wrong length' do
        let(:opts) { { between: ['HEAD'] } }

        it 'raises ArgumentError with an explanatory message' do
          expect { result }.to raise_error(
            ArgumentError,
            /must be an Array with exactly two non-nil values but was \["HEAD"\]/
          )
        end
      end

      context 'with between containing nil' do
        let(:opts) { { between: ['HEAD~1', nil] } }

        it 'raises ArgumentError with an explanatory message' do
          expect { result }.to raise_error(
            ArgumentError,
            /must be an Array with exactly two non-nil values but was \["HEAD~1", nil\]/
          )
        end
      end

      context 'with a non-integer count' do
        let(:opts) { { count: '5' } }

        it 'raises ArgumentError with an explanatory message' do
          expect { result }.to raise_error(ArgumentError, /must be an Integer but was "5"/)
        end
      end

      context 'with count set to false' do
        let(:opts) { { count: false } }

        it 'raises ArgumentError with an explanatory message' do
          expect { result }.to raise_error(ArgumentError, /must be an Integer but was false/)
        end
      end
    end
  end

  describe '#log' do
    subject(:result) { described_instance.log(count) }

    let(:count) { 30 }
    let(:log_instance) { instance_double(Git::Log) }

    before do
      allow(Git::Log).to receive(:new).with(described_instance, count).and_return(log_instance)
    end

    it 'constructs Git::Log with self and the given count and returns it' do
      expect(Git::Log).to receive(:new).with(described_instance, count).and_return(log_instance)
      expect(result).to be(log_instance)
    end

    context 'with default count' do
      subject(:result) { described_instance.log }

      it 'passes 30 as the default count' do
        expect(Git::Log).to receive(:new).with(described_instance, 30).and_return(log_instance)
        expect(result).to be(log_instance)
      end
    end
  end
end
