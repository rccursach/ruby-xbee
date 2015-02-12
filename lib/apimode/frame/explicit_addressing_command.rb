module XBee
  module Frame
    ##
    # Explicit Addressing ZigBee Command Frame (0x11)
    #
    # This frame allows ZigBee Application Layer fields to be specified for
    # a data transmission. This frame is similar to Zigbee Transmit Request (0x10)
    # but requires the ZigBee application layer addressing fields to be set.
    #
    # This frame is also used for triggering Programmable XBee (S2B) module
    # Over-the-Air firmware upgrade process.
    #
    class ExplicitAddressingCommand < Base
      def  api_identifier ; 0x11 ; end

      attr_accessor :destination_address, :destination_network, :source_endpoint, :destination_endpoint, :cluster_id, :profile_id, :broadcast_radius, :transmit_options, :payload, :payload_pack_string

      def initialize(frame_id = nil, destination_address = 0x000000000000ffff, destination_network = 0x0000fffe, source_endpoint = nil, destination_endpoint = nil, cluster_id = nil, profile_id = nil, broadcast_radius = 0x00, transmit_options = 0x00, payload = nil, payload_pack_string = "a*")
        self.frame_id = frame_id
        self.destination_address = destination_address
        self.destination_network = destination_network
        self.source_endpoint = source_endpoint
        self.destination_endpoint = destination_endpoint
        self.cluster_id = cluster_id
        self.profile_id = profile_id
        self.broadcast_radius = broadcast_radius
        self.transmit_options = transmit_options
        self.payload = payload
        self.payload_pack_string = payload_pack_string
      end

      def cmd_data=(data_string)
        # We need to read in the 64-bit destination_address in two 32-bit parts.
        dest_high = dest_low = 0
        self.frame_id, dest_high, dest_low, self.destination_network, self.source_endpoint, self.destination_endpoint, self.cluster_id, self.profile_id, self.broadcast_radius, self.transmit_options, self.payload = data_string.unpack("CNNnCCnnCC#{payload_pack_string}")
        self.destination_address = dest_high << 32 | dest_low
      end

      def cmd_data
        # We need to pack the 64-bit destination_address in two 32-bit parts.
        dest_high = (self.destination_address >> 32) & 0xFFFFFFFF
        dest_low = self.destination_address & 0xFFFFFFFF
        #if payload.nil?
        #  [self.frame]

    end
  end
end
