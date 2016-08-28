module XBee
  module Frame
    class ReceivedFrame < Base
      def initialize(frame_data)
        self.api_identifier = frame_data[0].unpack('H*').join.to_i(16) unless frame_data.nil?
        if $DEBUG then
          print "Initializing a ReceivedFrame of type 0x%02x | " % self.api_identifier
        elsif $VERBOSE
          puts "Initializing a ReceivedFrame of type 0x%02x" % self.api_identifier
        end
        self.cmd_data = frame_data[1..-1] unless frame_data.nil?
      end
    end

  end
end