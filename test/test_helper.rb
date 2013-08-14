require 'rubygems'
require 'simplecov'
require 'minitest/autorun'
require 'minitest/reporters'

#SimpleCov.command_name 'MiniTest'
#SimpleCov.start
MiniTest::Reporters.use!

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'ruby_xbee'
require 'version'

class MiniTest::Unit::TestCase
end
