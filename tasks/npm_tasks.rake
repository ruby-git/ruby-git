# frozen_string_literal: true

require 'rake/clean'

CLOBBER << 'node_modules'
CLOBBER << 'package-lock.json'
CLOBBER << '.husky/_'
