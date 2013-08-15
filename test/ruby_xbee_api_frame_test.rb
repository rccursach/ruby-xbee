$: << File.dirname(__FILE__)
require 'test_helper'
require 'socket'

class RubyXbeeApiFrameTest < MiniTest::Unit::TestCase
  def setup
      @unix_socket = '/tmp/ruby-xbee-test.sock'
      File.delete( @unix_socket ) if FileTest.exists?( @unix_socket )
      @server = UNIXServer.new(@unix_socket)
      @s = UNIXSocket.open(@unix_socket)
  end

  def test_frame
      Thread.fork(@server.accept) do |client| 
        t = [ 126, 0, 1, 0, 255 ]
        client.write(t.pack("ccccc"))
        client.close
      end
      
      assert_output("Initializing a ReceivedFrame of type 0x0\n") {
          xbee_frame = XBee::Frame.new(@s)
      }
      @s.close
      @server.close
      File.delete( @unix_socket ) if FileTest.exists?( @unix_socket )
  end

end
