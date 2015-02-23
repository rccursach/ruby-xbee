module XBee
  module Frame
    ##
    # ZigBee Explicit Rx Indicator (0x91) (AO=1)
    class ExplicitRxIndicator < ReceivedFrame
      def api_identifier ; 0x91 ; end
      attr_accessor :source_address, :source_network, :source_endpoint, :destination_endpoint, :cluster_id, :profile_id, :receive_options, :received_data

      def initialize(data = nil)
        super(data) && (yield self if block_given?)
      end

      def cmd_data=(data_string)
        # We need to read in the 64-bit source_address in two 32-bit parts.
        src_high = src_low = 0
        src_high, src_low, self.source_network, self.source_endpoint, self.destination_endpoint, self.cluster_id, self.profile_id, self.receive_options, self.received_data = data_string.unpack("NNnCCnnCa*")
        self.source_address = src_high << 32 | src_low
        @cmd_data = data_string
      end

    end
  end
end
