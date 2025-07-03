# frozen_string_literal: true

require 'test_helper'

class TestEachConflict < Test::Unit::TestCase
  def test_conflicts
    in_temp_repo('working') do
      # Setup a repository with a conflict
      g = Git.open('.')

      g.branch('new_branch').in_branch('commit message') do
        new_file('example.txt', "1\n2\n3")
        g.add
        true
      end

      g.branch('new_branch2').in_branch('test') do
        new_file('example.txt', "1\n4\n3")
        g.add
        true
      end

      g.merge('new_branch')

      begin
        g.merge('new_branch2')
      rescue Git::FailedError => e
        assert_equal(1, e.result.status.exitstatus)
        assert_match(/CONFLICT/, e.result.stdout)
      end

      assert_equal(1, g.lib.unmerged.size)

      # Check the conflict
      g.each_conflict do |file, your, their|
        assert_equal('example.txt', file)
        assert_equal("1\n2\n3\n", File.read(your))
        assert_equal("1\n4\n3\n", File.read(their))
      end
    end
  end
end
