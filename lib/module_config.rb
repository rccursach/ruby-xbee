module XBee
  module Config
    ##
    # A class for encapsulating UART communication parameters

    class XBeeUARTConfig
      attr_accessor :baud, :data_bits, :parity, :stop_bits

      ##
      # Defaults to standard 9600 baud 8N1 communications
      def initialize(baud = 9600, data_bits = 8, parity = 0, stop_bits = 1)
        self.baud = Integer(baud)
        self.data_bits = Integer(data_bits)
        self.parity = Integer(parity)
        self.stop_bits = Integer(stop_bits)
      end

    end

    ##
    # A class for encapsulating XBee programmable parameters
    class RFModuleParameter
      attr_accessor :at_name, :value, :default_value, :retrieved, :operation_mode

      def initialize(at_name, default_value)
        self.at_name= at_name
        self.default_value = default_value
        self.value = default_value
        self.retrieved = false
      end

    end

    class GuardTime < RFModuleParameter
      def initialize(default = 0x3E8)
        super("GT", default)
      end

      def in_seconds
        self.value / 1000.0
      end
    end

    class CommandModeTimeout < RFModuleParameter
      def initialize(default = 0x64)
        super("CT", default)
      end

      def in_seconds
        self.value / 1000.0
      end
    end

    class CommandCharacter < RFModuleParameter
      def initialize(default = '+')
        super("CC", default)
      end
    end


    class NodeDiscoverTimeout < RFModuleParameter
      def initialize(default = 0x82)
        super("NT", default)
      end

      def in_seconds
        self.value / 10.0
      end
    end

    class NodeIdentifier < RFModuleParameter
      def initialize(default = " ")
        super("NI", default)
      end
    end

    class ApiEnableMode < RFModuleParameter
      def initialize(default = 0x01)
        unless default == 0x01 or default == 0x02
          raise "XBee AP parameter range can be 1-2; 1 = API-enabled; 2 = API-enabled (with escaped control characters)"
        end
        super("AP", default)
      end

      def in_symbol
        unless self.value == 0x01 or self.value == 0x02
          raise "XBee AP parameter invalid range! Valid range 1-2; Set to: #{self.value}"
        end
        return :API1 if self.value == 0x01
        return :API2 if self.value == 0x02
      end
    end
  end
end
