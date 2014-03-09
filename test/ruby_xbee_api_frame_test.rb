$: << File.dirname(__FILE__)
require 'test_helper'
require 'socket'
##
# The main goal of these testcases is to test basic API frame reading from
# socket, ensuring the integrity of frames by checksum calculation and
# ability to construct frames. Some of the frame examples for testing are
# based on the XBee reference manuals but feel free to run with your
# imagination.
# ==================================================
# Currently known frames, o = covered by test frames
# ==================================================
# o - 0x08 - AT Command
# x - 0x09 - AT Command - Queue Parameter Value
# x - 0x10 - ZigBee Transmit Request
# x - 0x11 - Explicit Addressing ZigBee Command Frame
# o - 0x17 - Remote Command Request
# x - 0x21 - Create Source Route 
# x - 0x88 - AT Command Response
# o - 0x8a - Modem Status
# o - 0x8b - ZigBee Transmit Status
# x - 0x90 - ZigBee Receive Packet (AO=0)
# x - 0x91 - ZigBee Explicit Rx Indicator (AO=1)
# o - 0x92 - ZigBee IO Data Sample Rx Indicator 
# x - 0x94 - XBee Sensor Read Indicator (AO=0)
# x - 0x95 - Node Identification Indicator (AO=0)
# o - 0x97 - Remote Command Response
# x - 0xA0 - Over-the-Air Firmware Update Status
# x - 0xA1 - Route Record Indicator
# x - 0xA3 - Many-to-One Route Request Indicator
class RubyXbeeApiFrameTest < MiniTest::Test
  def setup
    @unix_socket = '/tmp/ruby-xbee-test.sock'
    File.delete( @unix_socket ) if FileTest.exists?( @unix_socket )
    @server = UNIXServer.new(@unix_socket)
    @s = UNIXSocket.open(@unix_socket)
  end

  ##
  # We test sending the most simplistic packet possible
  # (unknown frame type)
  # +----------------------------+-----------------------------+------+
  # |___________Header___________|____________Frame____________|      |
  # | SDelim | DlenMSB | DlenLSB | Type | ID |   A T   | (Par) | CSum |
  # +--------+---------+---------+------+----+---------+-------+------+
  # |  0x7e  |   0x00  |   0x00  | 0x00 |    |    |    |       | 0xff |
  # +--------+---------+---------+------+----+-----------------+------+
  def test_frame_00
    Thread.fork(@server.accept) do |client| 
      f = [ 0x7e, 0x00, 0x01, 0x00, 0xff]
      client.write(f.pack("c*"))
      client.close
    end
      
    assert_output("Initializing a ReceivedFrame of type 0x0\n") {
      xbee_frame = XBee::Frame.new(@s)
    }
  end

  ##
  # We test sending the most simplistic packet possible with incorrect checksum
  # (unknown frame type)
  # +----------------------------+-----------------------------+------+
  # |___________Header___________|____________Frame____________|      |
  # | SDelim | DlenMSB | DlenLSB | Type | ID |   A T   | (Par) | CSum |
  # +--------+---------+---------+------+----+---------+-------+------+
  # |  0x7e  |   0x00  |   0x00  | 0x00 |    |    |    |       | 0x80 |
  # +--------+---------+---------+------+----+-----------------+------+
  def test_bad_checksum
    Thread.fork(@server.accept) do |client|
      f = [ 0x7e, 0x00, 0x01, 0x00, 0x80]
      client.write(f.pack("c*"))
      client.close
    end
      
    runtimeerror_raised = assert_raises(RuntimeError) {
      xbee_frame = XBee::Frame.new(@s)
    }
    assert_equal("Bad checksum - data discarded", runtimeerror_raised.message)
  end
  
  ##
  # AT Command (0x08) that allows joining by setting NJ to 0xFF; AT = NJ
  # +----------------------------+-----------------------------+------+
  # |___________Header___________|____________Frame____________|      |
  # | SDelim | DlenMSB | DlenLSB | Type | ID |   A T   | (Par) | CSum |
  # +--------+---------+---------+------+----+---------+-------+------+
  # |  0x7e  |   0x00  |   0x05  | 0x08 |0x01|0x4e|0x4a| 0xff  | 0x5f |
  # +--------+---------+---------+------+----+-----------------+------+
  def test_allow_join
    Thread.fork(@server.accept) do |client|
      f = [ 0x7e, 0x00, 0x05, 0x08, 0x01, 0x4e, 0x4a, 0xff, 0x5f ]
      client.write(f.pack("c*"))
      client.close
    end
    
    assert_output("Initializing a ReceivedFrame of type 0x8\n") {
      xbee_frame = XBee::Frame.new(@s)
      assert_equal("\x01NJ\xFF".force_encoding("iso-8859-1"), xbee_frame.cmd_data.force_encoding("iso-8859-1"))
    }
  end
  
  ##
  # AT Command (0x08) for Network Discovery; AT = ND
  # +----------------------------+-----------------------------+------+
  # |___________Header___________|____________Frame____________|      |
  # | SDelim | DlenMSB | DlenLSB | Type | ID |   A T   | (Par) | CSum |
  # +--------+---------+---------+------+----+---------+-------+------+
  # |  0x7e  |   0x00  |   0x04  | 0x08 |0x01|0x4e|0x44|       | 0x64 |
  # +--------+---------+---------+------+----+-----------------+------+
  def test_network_discovery
    Thread.fork(@server.accept) do |client|
      f = [ 0x7e, 0x00, 0x04, 0x08, 0x01, 0x4e, 0x44, 0x64 ]
      client.write(f.pack("c*"))
      client.close
    end
    
    assert_output("Initializing a ReceivedFrame of type 0x8\n") {
      xbee_frame = XBee::Frame.new(@s)
      assert_equal("\x01ND", xbee_frame.cmd_data)
    }
  end
  
  ##
  # Remote Command Request (0x17)
  # Send remote command to the coordinator and set AD1/DIO1 as a digital input
  # applying the changes to force IO update; AT = D1
  # +----------------------------+-----------------------------------------------------------------------+------+
  # |___________Header___________|_________________________________Frame_________________________________|      |
  # | SDelim | DlenMSB | DlenLSB | Type | ID | CoordinatorAddress | Dest16 | RemComOpt |   A T   | (Par) | CSum |
  # +--------+---------+---------+------+----+--------------------+--------+-----------+---------+-------+------+
  # |  0x7e  |   0x00  |   0x10  | 0x17 |0x01| 0x0123456789abcdef | 0xfcfe |   0x02    |0x44|0x31| 0x03  | 0xb3 |
  # +--------+---------+---------+------+----+--------------------+--------+-----------+----+----+-------+------+
  def test_remote_command_request
    Thread.fork(@server.accept) do |client|
      f = [ 0x7e, 0x00, 0x10, 0x17, 0x01, 0x01, 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef, 0xfc, 0xfe, 0x02, 0x44, 0x31, 0x03, 0xb3 ]
      client.write(f.pack("c*"))
      client.close
    end
    assert_output("Initializing a ReceivedFrame of type 0x17\n") {
      xbee_frame = XBee::Frame.new(@s)
      assert_equal("\x01\x01\x23\x45\x67\x89\xAB\xCD\xEF\xFC\xFE\x02D1\x03".force_encoding("iso-8859-1"), xbee_frame.cmd_data.force_encoding("iso-8859-1"))
    }
  end
  
  ##
  # AT Command Response (0x88) are sent in a response to an AT Command. Some
  # commands trigger multiple responses, like the ATND (Node Discover) command.
  # AT = BD
  # +----------------------------+---------------------------------+------+
  # |___________Header___________|______________Frame______________|      |
  # | SDelim | DlenMSB | DlenLSB | Type | ID |   A T   |Status|Data| CSum |
  # +--------+---------+---------+------+----+---------+------+----+------+
  # |  0x7e  |   0x00  |   0x05  | 0x88 |0x01|0x42|0x44| 0x00 |    | 0xF0 |
  # +--------+---------+---------+------+----+----------------+----+------+
  def test_command_response
      
  end

  ##
  # Modem Status (0x8A) These frames are sent on specific conditions
  # This frame is sent by end-device upon joining a network
  # +----------------------------+---------------+------+
  # |___________Header___________|_____Frame_____|      |
  # | SDelim | DlenMSB | DlenLSB | Type | Status | CSum |
  # +--------+---------+---------+------+--------+------+
  # |  0x7e  |   0x00  |   0x02  | 0x8a |  0x02  | 0x73 |
  # +--------+---------+---------+------+--------+------+
  def test_modem_status_joined_network
    Thread.fork(@server.accept) do |client|
      f = [ 0x7e, 0x00, 0x02, 0x8a, 0x02, 0x73 ]
      client.write(f.pack("c*"))
      client.close
    end
    
    assert_output("Initializing a ReceivedFrame of type 0x8a\n") {
      xbee_frame = XBee::Frame.new(@s)
      assert_equal("\x02", xbee_frame.cmd_data)
      assert_equal(2, xbee_frame.status[0])
      assert_equal(:Associated, xbee_frame.status[1])
    }
  end  

  ##
  # Modem Status (0x8A) These frames are sent on specific conditions
  # This frame is sent by coordinator upon forming a network
  # (currently this is unimplemented and raises a RuntimeError)
  # BORKEN
  # +----------------------------+---------------+------+
  # |___________Header___________|_____Frame_____|      |
  # | SDelim | DlenMSB | DlenLSB | Type | Status | CSum |
  # +--------+---------+---------+------+--------+------+
  # |  0x7e  |   0x00  |   0x02  | 0x8a |  0x06  | 0x6f |
  # +--------+---------+---------+------+--------+------+
  def test_modem_status_coordinator_started_invalid_status
    Thread.fork(@server.accept) do |client|
      f = [ 0x7e, 0x00, 0x02, 0x8a, 0x06, 0x6f ]
      client.write(f.pack("c*"))
      client.close
    end
    
    assert_output("Initializing a ReceivedFrame of type 0x8a\n") {
      runtimeerror_raised = assert_raises(RuntimeError) {
        xbee_frame = XBee::Frame.new(@s);
      }
      assert_equal("ModemStatus frame appears to include an invalid status value: 0x06", runtimeerror_raised.message)
    }
  end
  
  ##
  # ZigBee Transmit Status (0x8B) When a TX Request is completed, the module
  # sends a TX Status message to indicate successful transfer or failure.
  # +----------------------------+----------------------------------------------------------------------------+------+
  # |___________Header___________|___________________________________Frame____________________________________|      |
  # | SDelim | DlenMSB | DlenLSB | Type | ID | Dest16 | TransmitRetryCount | DeliveryStatus | DiscoveryStatus | CSum |
  # +--------+---------+---------+------+----+--------+--------------------+----------------+-----------------+------+
  # |  0x7e  |   0x00  |   0x07  | 0x8b |0x01| 0x7c84 |        0x00        |      0x00      |       0x01      | 0x72 |
  # +--------+---------+---------+------+----+--------+--------------------+----------------+-----------------+------+  
  def test_zigbee_transmit_status_ok
    Thread.fork(@server.accept) do |client|
      f = [ 0x7e, 0x00, 0x07, 0x8b, 0x01, 0x7c, 0x84, 0x00, 0x00, 0x01, 0x72 ]
      client.write(f.pack("c*"))
      client.close
    end
    
    assert_output("Initializing a ReceivedFrame of type 0x8b\n") {
      xbee_frame = XBee::Frame.new(@s)
    }
  end
  
  ##
  # ZigBee Transmit Status (0x8B) with escaped payload
  # +----------------------------+----------------------------------------------------------------------------+------+
  # |___________Header___________|___________________________________Frame____________________________________|      |
  # | SDelim | DlenMSB | DlenLSB | Type | ID | Dest16 | TransmitRetryCount | DeliveryStatus | DiscoveryStatus | CSum |
  # +--------+---------+---------+------+----+--------+--------------------+----------------+-----------------+------+
  # |  0x7e  |   0x00  |   0x07  | 0x8b |0x01| 0x7d84 |        0x00        |      0x00      |       0x01      | 0x71 |
  # +--------+---------+---------+------+----+--------+--------------------+----------------+-----------------+------+  
  def test_zigbee_transmit_status_escaped_dataload
    Thread.fork(@server.accept) do |client|
      # 7d needs to be escaped 7d => 7d 5d
      f = [ 0x7e, 0x00, 0x07, 0x8b, 0x01, 0x7d, 0x5d, 0x84, 0x00, 0x00, 0x01, 0x71 ]
      client.write(f.pack("c*"))
      client.close
    end
    
    assert_output("Initializing a ReceivedFrame of type 0x8b\n") {
      xbee_frame = XBee::Frame.new(@s)
      assert_equal("\x01\x7d\x84\x00\x00\x01".force_encoding("iso-8859-1"), xbee_frame.cmd_data.force_encoding("iso-8859-1"))
    }
  end
  
  ##
  # ZigBee IO Data Sample Rx Indicator (0x92)
  # When the module receives an IO sample fram efrom remote device, it sends the
  # sample out the UART using this frame (when AO=0). Only modules running API
  # firmware will send IO samples out the UART. In a wireless sensor network
  # this frame is probably the most important data carrier for sensory payloads.
  # +----------------------------+
  # |___________Header___________|
  # | SDelim | DlenMSB | DlenLSB |
  # +--------+---------+---------+
  # |  0x7e  |   0x00  |   0x14  |
  # +--------+---------+---------+------------------------------------------------------------------------------------+------+
  # |______________________________________________________Frame______________________________________________________|      |
  # | Type | 64-bitRemoteSource | SNet16 | ReceiveOptions | NoOfSamples | DChanlMask | AChanlMask | DSample | ASample | CSum |
  # +------+--------------------+--------+----------------+-------------+------------+------------+---------+---------+------+
  # | 0x92 | 0x0012a20040522baa | 0x7c84 |      0x01      |     0x01    |   0x001c   |    0x02    | 0x0014  | 0x0225  | 0xf7 |
  # +------+--------------------+--------+----------------+-------------+------------+------------+---------+---------+------+
  def test_zigbee_io_data_sample_rx_indicator
    Thread.fork(@server.accept) do |client|
      f = [ 0x7e, 0x00, 0x14, 0x92, 0x00, 0x12, 0xa2, 0x00, 0x40, 0x52, 0x2b, 0xaa, 0x7c, 0x84, 0x01, 0x01, 0x00, 0x1c, 0x02, 0x00, 0x14, 0x02, 0x25, 0xf7 ]
      client.write(f.pack("c*"))
      client.close
    end
    
    assert_output("Initializing a ReceivedFrame of type 0x92\n") {
        xbee_frame = XBee::Frame.new(@s)
        assert_equal("\x00\x12\xa2\x00\x40\x52\x2b\xaa\x7c\x84\x01\x01\x00\x1c\x02\x00\x14\x02\x25".force_encoding("iso-8859-1"), xbee_frame.cmd_data.force_encoding("iso-8859-1"))
    }
  end
  
  ##
  # Remote Command Response (0x97)
  # If a module receives a remote command response RF data frame in response to a Remote AT Command Request,
  # the module will send out a Remote AT Command response message back. Some commands can trigger sending back
  # multiple frames, for example Node Discover (ND).
  # +----------------------------+---------------------------------------------------------------------------+------+
  # |___________Header___________|___________________________________Frame___________________________________|      |
  # | SDelim | DlenMSB | DlenLSB | Type | ID | 64-bitRemoteSource | SNet16 |   A T   | CStatus | CommandData | CSum |
  # +--------+---------+---------+------+----+--------------------+--------+---------+---------+-------------+------+
  # |  0x7e  |   0x00  |   0x13  | 0x97 |0x04| 0x0012a20040522baa | 0x7c84 |0x53|0x4c|   0x00  | 0x40522baa  | 0x43 |
  # +--------+---------+---------+------+----+--------------------+--------+---------+---------+-------------+------+
  def test_remote_command_response_ok
    Thread.fork(@server.accept) do |client|
      f = [ 0x7e, 0x00, 0x13, 0x97, 0x04, 0x00, 0x12, 0xa2, 0x00, 0x40, 0x52, 0x2b, 0xaa, 0x7c, 0x84, 0x53, 0x4c, 0x00, 0x40, 0x52, 0x2b, 0xaa, 0x43 ]
      client.write(f.pack("c*"))
      client.close
    end
    
    assert_output("Initializing a ReceivedFrame of type 0x97\n") {
      xbee_frame = XBee::Frame.new(@s)
    }
  end
  
  ##
  # Remote Command Response (0x97) - Remote Command Transmission Failed
  # At the moment this is generic ReceivedFrame where api_identifier and cmd_data are populated
  # +----------------------------+---------------------------------------------------------------------------+------+
  # |___________Header___________|___________________________________Frame___________________________________|      |
  # | SDelim | DlenMSB | DlenLSB | Type | ID | 64-bitRemoteSource | SNet16 |   A T   | CStatus | CommandData | CSum |
  # +--------+---------+---------+------+----+--------------------+--------+---------+---------+-------------+------+
  # |  0x7e  |   0x00  |   0x13  | 0x97 |0x04| 0x0012a20040522baa | 0x7c84 |0x53|0x4c|   0x04  | 0x40522baa  | 0x3f |
  # +--------+---------+---------+------+----+--------------------+--------+---------+---------+-------------+------+
  def test_remote_command_response_transmission_failed
    Thread.fork(@server.accept) do |client|
      f = [ 0x7e, 0x00, 0x13, 0x97, 0x04, 0x00, 0x12, 0xa2, 0x00, 0x40, 0x52, 0x2b, 0xaa, 0x7c, 0x84, 0x53, 0x4c, 0x04, 0x40, 0x52, 0x2b, 0xaa, 0x3f ]
      client.write(f.pack("c*"))
      client.close
    end
    
    assert_output("Initializing a ReceivedFrame of type 0x97\n") {
      xbee_frame = XBee::Frame.new(@s)
      assert_equal("\x97".force_encoding("iso-8859-1"), xbee_frame.api_identifier.force_encoding("iso-8859-1"))
      assert_equal("\x04\x00\x12\xa2\x00\x40\x52\x2b\xaa\x7c\x84\x53\x4c\x04\x40\x52\x2b\xaa".force_encoding("iso-8859-1"), xbee_frame.cmd_data.force_encoding("iso-8859-1"))
    }
  end
  
  ##
  # Remote Command Response (0x97) - Invalid status byte
  # At the moment this is generic ReceivedFrame where api_identifier and cmd_data are populated
  # +----------------------------+---------------------------------------------------------------------------+------+
  # |___________Header___________|___________________________________Frame___________________________________|      |
  # | SDelim | DlenMSB | DlenLSB | Type | ID | 64-bitRemoteSource | SNet16 |   A T   | CStatus | CommandData | CSum |
  # +--------+---------+---------+------+----+--------------------+--------+---------+---------+-------------+------+
  # |  0x7e  |   0x00  |   0x13  | 0x97 |0x04| 0x0012a20040522baa | 0x7c84 |0x53|0x4c|   0x05  | 0x40522baa  | 0x3e |
  # +--------+---------+---------+------+----+--------------------+--------+---------+---------+-------------+------+
  def test_remote_command_response_invalid_status_byte
    Thread.fork(@server.accept) do |client|
      f = [ 0x7e, 0x00, 0x13, 0x97, 0x04, 0x00, 0x12, 0xa2, 0x00, 0x40, 0x52, 0x2b, 0xaa, 0x7c, 0x84, 0x53, 0x4c, 0x05, 0x40, 0x52, 0x2b, 0xaa, 0x3e ]
      client.write(f.pack("c*"))
      client.close
    end
    
    assert_output("Initializing a ReceivedFrame of type 0x97\n") {
      runtimeerror_raised = assert_raises(RuntimeError) {
        xbee_frame = XBee::Frame.new(@s)
      }
      assert_equal("AT Command Response frame appears to include an invalid status: 0x05", runtimeerror_raised.message)
    }
  end
  
  ##
  # Teardown
  def teardown
    @s.close
    @server.close
    File.delete( @unix_socket ) if FileTest.exists?( @unix_socket )
  end

end
