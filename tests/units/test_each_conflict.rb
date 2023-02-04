#!/usr/bin/env ruby

require 'test_helper'

class TestEachConflict < Test::Unit::TestCase

  def test_conflicts
    in_temp_repo('working') do
      g = Git.open('.')

      g.branch('new_branch').in_branch('test') do
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
      rescue
      end

      g.each_conflict do |file, your, their|
        assert_equal('example.txt', file)
        assert_equal("1\n2\n3\n", File.read(your))
        assert_equal("1\n4\n3\n", File.read(their))
      end
    end
  end
end
