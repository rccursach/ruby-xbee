require 'versioncheck'

rb_vc = VersionCheck.rubyversion
if !rb_vc.have_version?(2,1)
  require 'simplecov'
  SimpleCov.command_name 'MiniTest'
  SimpleCov.start
end

if ENV['TRAVIS'] == "true" && ENV['CI'] =="true" 
  require 'coveralls'
  Coveralls.wear!
end

require 'rubygems'
require 'minitest/autorun'
require 'minitest/reporters'

MiniTest::Reporters.use!

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'bin'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'ruby_xbee'