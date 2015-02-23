$: << File.dirname(__FILE__)
require 'ruby_xbee_api_frame_test'
# Test cases for ZigBee Explicit Addressing Command (Frame Type: 0x11)
# Test cases to cover the construction/sending and receiving/decoding
# scenarios.
class ExplicitAddressingCommand < RubyXbeeApiFrameTest

	##
	# Explicit Addressing ZigBee Command Frame (0x11)
	# This allows ZigBee application layer fields (endpoint and cluster ID) to be specified for a data transmission.
	# Here we send a valid OTA start request without encryption and OTA password set to broadcast destination network
	# +----------------------------+--------------------------------------------------------------------------------------------------------------------------------+------+
	# |___________Header___________|______________________________________________________________Frame_____________________________________________________________|      |
	# | SDelim | DlenMSB | DlenLSB | Type | ID | 64-bitDestination  | Dest16 | SrcEndPnt | DestEndPnt | ClusterID | ProfileID | BCRadius | Options |  Data Payload  | CSum |
	# +--------+---------+---------+------+----+--------------------+--------+-----------+------------+-----------+-----------+----------+---------+----------------+------+
	# |  0x7e  |   0x00  |   0x15  | 0x11 |0x10| 0x0101010101010ABC | 0xfffe |    0xE8   |    0xE8    |   0x1000  |   0xC105  |   0x00   |  0x00   |      0x00      | 0x6F |
	# +--------+---------+---------+------+----+--------------------+--------+-----------+------------+-----------------------+----------+---------+----------------+------+
	def test_eac_receive_ota_init_no_password
		Thread.fork(@server.accept) do |client|
			f = [ 0x7E, 0x00, 0x15, 0x11, 0x10, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x0A, 0xBC, 0xFF, 0xFE, 0xE8, 0xE8, 0x10, 0x00, 0xC1, 0x05, 0x00, 0x00, 0x00, 0x6F ]
			client.write(f.pack("c*"))
			client.close
		end


		xbee_frame = XBee::Frame.new(@s)
		assert_equal("\x10\x01\x01\x01\x01\x01\x01\x0A\xBC\xFF\xFE\xE8\xE8\x10\x00\xC1\x05\x00\x00\x00".force_encoding("iso-8859-1"), xbee_frame.cmd_data.force_encoding("iso-8859-1"))
		assert_equal(0x11, xbee_frame.api_identifier)
	end

	##
	# Explicit Addressing ZigBee Command Frame (0x11)
	# This allows ZigBee application layer fields (endpoint and cluster ID) to be specified for a data transmission.
	# Here we send a valid OTA start request without encryption and OTA password set to broadcast destination network
	# +----------------------------+--------------------------------------------------------------------------------------------------------------------------------+------+
	# |___________Header___________|______________________________________________________________Frame_____________________________________________________________|      |
	# | SDelim | DlenMSB | DlenLSB | Type | ID | 64-bitDestination  | Dest16 | SrcEndPnt | DestEndPnt | ClusterID | ProfileID | BCRadius | Options |  Data Payload  | CSum |
	# +--------+---------+---------+------+----+--------------------+--------+-----------+------------+-----------+-----------+----------+---------+----------------+------+
	# |  0x7e  |   0x00  |   0x15  | 0x11 |0x10| 0x0101010101010ABC | 0xfffe |    0xE8   |    0xE8    |   0x1000  |   0xC105  |   0x00   |  0x00   |      0x00      | 0x6F |
	# +--------+---------+---------+------+----+--------------------+--------+-----------+------------+-----------------------+----------+---------+----------------+------+
	def test_eac_create_ota_init_no_password_default_payload_pack
		Thread.fork(@server.accept) do |client|
			frame = XBee::Frame::ExplicitAddressingCommand.new(0x10, 0x0101010101010ABC, 0x0000fffe, 0xE8, 0xE8, 0x1000, 0xC105, 0x00, 0x00)
			client.write(frame._dump)
			client.close
		end

		xbee_frame = XBee::Frame.new(@s)
		assert_equal("\x10\x01\x01\x01\x01\x01\x01\x0A\xBC\xFF\xFE\xE8\xE8\x10\x00\xC1\x05\x00\x00\x00".force_encoding("iso-8859-1"), xbee_frame.cmd_data.force_encoding("iso-8859-1"))
		assert_equal(0x11, xbee_frame.api_identifier)

		# Build the frame from the received data
		frame = XBee::Frame::ExplicitAddressingCommand.new()
		frame.cmd_data = xbee_frame.cmd_data

		assert_equal 0x10, frame.frame_id
		assert_equal 0x0101010101010ABC, frame.destination_address
		assert_equal 0xfffe, frame.destination_network
		assert_equal 0xE8, frame.source_endpoint
		assert_equal 0xE8, frame.destination_endpoint
		assert_equal 0x1000, frame.cluster_id
		assert_equal 0xc105, frame.profile_id
		assert_equal 0x00, frame.broadcast_radius
		assert_equal 0x00, frame.transmit_options
		assert_equal "\0", frame.payload

	end

	##
	# Explicit Addressing ZigBee Command Frame (0x11)
	# This allows ZigBee application layer fields (endpoint and cluster ID) to be specified for a data transmission.
	# Here we send a valid OTA start request without encryption and OTA password set to broadcast destination network
	# +----------------------------+--------------------------------------------------------------------------------------------------------------------------------+------+
	# |___________Header___________|______________________________________________________________Frame_____________________________________________________________|      |
	# | SDelim | DlenMSB | DlenLSB | Type | ID | 64-bitDestination  | Dest16 | SrcEndPnt | DestEndPnt | ClusterID | ProfileID | BCRadius | Options |  Data Payload  | CSum |
	# +--------+---------+---------+------+----+--------------------+--------+-----------+------------+-----------+-----------+----------+---------+----------------+------+
	# |  0x7e  |   0x00  |   0x15  | 0x11 |0x10| 0x0101010101010ABC | 0xfffe |    0xE8   |    0xE8    |   0x1000  |   0xC105  |   0x00   |  0x00   |      0x00      | 0x6F |
	# +--------+---------+---------+------+----+--------------------+--------+-----------+------------+-----------------------+----------+---------+----------------+------+
	# This is an interesting packet because in AP2 (with escaped control characters) The Frame Type gets escaped
	def test_eac_create_ota_init_no_password_default_payload_pack_ap2
		Thread.fork(@server.accept) do |client|
			frame = XBee::Frame::ExplicitAddressingCommand.new(0x10, 0x0101010101010ABC, 0x0000fffe, 0xE8, 0xE8, 0x1000, 0xC105, 0x00, 0x00)
			client.write(frame._dump(:API2))
			client.close
		end

		xbee_frame = XBee::Frame.new(@s, :API2)
		assert_equal("\x10\x01\x01\x01\x01\x01\x01\x0A\xBC\xFF\xFE\xE8\xE8\x10\x00\xC1\x05\x00\x00\x00".force_encoding("iso-8859-1"), xbee_frame.cmd_data.force_encoding("iso-8859-1"))
		assert_equal(0x11, xbee_frame.api_identifier)

		# Build the frame from the received data
		frame = XBee::Frame::ExplicitAddressingCommand.new()
		frame.cmd_data = xbee_frame.cmd_data

		assert_equal 0x10, frame.frame_id
		assert_equal 0x0101010101010ABC, frame.destination_address
		assert_equal 0xfffe, frame.destination_network
		assert_equal 0xE8, frame.source_endpoint
		assert_equal 0xE8, frame.destination_endpoint
		assert_equal 0x1000, frame.cluster_id
		assert_equal 0xc105, frame.profile_id
		assert_equal 0x00, frame.broadcast_radius
		assert_equal 0x00, frame.transmit_options
		assert_equal "\0", frame.payload

	end

	##
	# Explicit Addressing ZigBee Command Frame (0x11)
	# This allows ZigBee application layer fields (endpoint and cluster ID) to be specified for a data transmission.
	# Here we send a valid OTA start request without encryption and OTA password set to broadcast destination network
	# +----------------------------+--------------------------------------------------------------------------------------------------------------------------------+------+
	# |___________Header___________|______________________________________________________________Frame_____________________________________________________________|      |
	# | SDelim | DlenMSB | DlenLSB | Type | ID | 64-bitDestination  | Dest16 | SrcEndPnt | DestEndPnt | ClusterID | ProfileID | BCRadius | Options |  Data Payload  | CSum |
	# +--------+---------+---------+------+----+--------------------+--------+-----------+------------+-----------+-----------+----------+---------+----------------+------+
	# |  0x7e  |   0x00  |   0x15  | 0x11 |0x10| 0x0101010101010ABC | 0xfffe |    0xE8   |    0xE8    |   0x1000  |   0xC105  |   0x00   |  0x00   |      0x00      | 0x6F |
	# +--------+---------+---------+------+----+--------------------+--------+-----------+------------+-----------------------+----------+---------+----------------+------+
	# Here we send the packet in AP2 mode (escaped) but receive the packet in AP1 mode (unescaped) - the world should collapse because of bad checksum
	def test_eac_create_ota_init_no_password_default_payload_pack_ap2
		Thread.fork(@server.accept) do |client|
			frame = XBee::Frame::ExplicitAddressingCommand.new(0x10, 0x0101010101010ABC, 0x0000fffe, 0xE8, 0xE8, 0x1000, 0xC105, 0x00, 0x00)
			client.write(frame._dump(:API2))
			client.close
		end

		runtimeerror_raised = assert_raises(RuntimeError) {
			xbee_frame = XBee::Frame.new(@s)
		}
		assert_equal("Bad checksum - data discarded", runtimeerror_raised.message)

	end
end
