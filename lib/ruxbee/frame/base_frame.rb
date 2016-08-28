module XBee
  module Frame
    
    class Base
      attr_accessor :api_identifier, :cmd_data, :frame_id

      def api_identifier ; @api_identifier ||= 0x00 ; end

      def cmd_data ; @cmd_data ||= "" ; end

      def length ; data.length ; end

      def data
        Array(api_identifier).pack("C") + cmd_data
      end

      def _dump(api_mode = :API1)
        unless api_mode == :API1 or api_mode == :API2
          raise "XBee api_mode must be either :API1 (non-escaped) or :API2 (escaped, default)"
        end
        raise "Too much data (#{self.length} bytes) to fit into one frame!" if (self.length > 0xFFFF)

        if (api_mode == :API1)
          "~" + [length].pack("n") + data + [Frame.checksum(data)].pack("C")
        elsif (api_mode == :API2)
          "~" + [length].pack("n").xb_escape + data.xb_escape + [Frame.checksum(data)].pack("C")
        end
      end
    end

  end
end