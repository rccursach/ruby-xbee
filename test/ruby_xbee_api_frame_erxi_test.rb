$: << File.dirname(__FILE__)
require 'ruby_xbee_api_frame_test'
# Test cases for ZigBee Explicit Rx Indicator (Frame Type: 0x91)
# Test cases to cover the construction/sending and receiving/decoding
# scenarios.
class ExplicitRxIndicator < RubyXbeeApiFrameTest
	##
  # ZigBee Explicit Rx Indicator - (0x91) When the modem receives a ZigBee RF packet
  # it is sent out the UART using this message type (when AO=1).
  # +----------------------------+----------------------------------------------------------------------------------------------------------------+------+
  # |___________Header___________|_____________________________________________________Frame______________________________________________________|      |
  # | SDelim | DlenMSB | DlenLSB | Type | 64-bit Source Addr | Src.16 | SrcEndPnt | DestEndPnt | ClusterID | ProfileID | Options |  Data Payload  | CSum |
  # +--------+---------+---------+------+--------------------+--------+-----------+------------+-----------+-----------+---------+----------------+------+
  # |  0x7E  |   0x00  |   0x13  | 0x91 | 0x1234567890ABCDEF | 0x1234 |    0xE8   |    0xE8    |   0x0011  |   0xC105  |   0x01  |      0x43      | 0x32 |
  # +--------+---------+---------+------+--------------------+--------+-----------+------------+-----------+-----------+---------+----------------+------+
  # This frame is sent in response to type ZigBee Explicit Addressing Command (Frame Type: 0x11). The cluster 0x0011 is used by Digi as Virtual serial line
  # And use for example in OTA firmware upgrade
  def test_zigbee_explicit_rx_indicator_xmodem_start
    Thread.fork(@server.accept) do |client|
      f = [ 0x7E, 0x00, 0x13, 0x91, 0x12, 0x34, 0x56, 0x78, 0x90, 0xAB, 0xCD, 0xEF,
            0x12, 0x34, 0xE8, 0xE8, 0x00, 0x11, 0xC1, 0x05, 0x01, 0x43, 0x32 ]
      client.write(f.pack("c*"))
      client.close
    end

    xbee_frame = XBee::Frame.new(@s)

    assert_equal 0x91, xbee_frame.api_identifier
		assert_equal 0x1234567890ABCDEF, xbee_frame.source_address
		assert_equal 0x1234, xbee_frame.source_network
		assert_equal 0xE8, xbee_frame.source_endpoint
		assert_equal 0xE8, xbee_frame.destination_endpoint
		assert_equal 0x0011, xbee_frame.cluster_id
		assert_equal 0xc105, xbee_frame.profile_id
		assert_equal 0x01, xbee_frame.receive_options
		assert_equal "C".force_encoding("iso-8859-1"), xbee_frame.received_data.force_encoding("iso-8859-1")


		# Let's construct a frame from scratch and use the data previously received
		frame = XBee::Frame::ExplicitRxIndicator.new
		frame.cmd_data = xbee_frame.cmd_data

		assert_equal frame.api_identifier, xbee_frame.api_identifier
		assert_equal frame.source_address, xbee_frame.source_address
		assert_equal frame.source_network, xbee_frame.source_network
		assert_equal frame.source_endpoint, xbee_frame.source_endpoint
		assert_equal frame.destination_endpoint, xbee_frame.destination_endpoint
		assert_equal frame.cluster_id, xbee_frame.cluster_id
		assert_equal frame.profile_id, xbee_frame.profile_id
		assert_equal frame.receive_options, xbee_frame.receive_options
		assert_equal frame.received_data, xbee_frame.received_data
		
  end
end
