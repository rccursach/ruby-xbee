module XBee
  module Frame

    class ReceivePacket16 < Base
      attr_reader :rssi, :address_16_bits, :options
      @rssi = 0x00
      @address_16_bits = 0x0000
      @options = 0x00

      def initialize(frame_data)
        self.api_identifier = frame_data[0].unpack('H*').join.to_i(16) unless frame_data.nil?
        if $DEBUG then
          print "Initializing a ReceivedFrame of type 0x%02x | " % self.api_identifier
        elsif $VERBOSE
          puts "Initializing a ReceivedFrame of type 0x%02x" % self.api_identifier
        end
        @address_16_bits = frame_data[1..2] unless frame_data.nil?
        @rssi = frame_data[3] unless frame_data.nil?
        @options = frame_data[4] unless frame_data.nil?
        self.cmd_data = frame_data[5..-1] unless frame_data.nil?
      end
    end

  end
end