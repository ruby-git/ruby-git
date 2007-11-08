#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/test_helper'

class TestInit < Test::Unit::TestCase
  def setup
  end
  
  def test_open 
    Git.open
  end
end
