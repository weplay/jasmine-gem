require "rubygems"
require "bundler"

Bundler.setup(:default, :test)

require 'spec'

require File.expand_path(File.join(File.dirname(__FILE__), "../lib/jasmine"))
