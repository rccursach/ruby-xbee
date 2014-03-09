require 'rubygems'
require 'versioncheck'
require 'minitest/autorun'
require 'minitest/reporters'

rb_vc = VersionCheck.rubyversion
if !rb_vc.have_version?(2,0)
  require 'simplecov'
  SimpleCov.command_name 'MiniTest'
  SimpleCov.start
end

MiniTest::Reporters.use!

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'bin'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'ruby_xbee'
require 'coveralls'

Coveralls.wear!