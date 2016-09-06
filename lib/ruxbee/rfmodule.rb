require 'serialport'
require 'ruxbee/config'
module XBee
  ##
  # This is it, the base class where it all starts. Command mode or API mode, version 1 or version 2, all XBees descend
  # from this class.
  class RFModule
    #include XBee
    include Config

    attr_accessor :xbee_serialport, :xbee_uart_config, :guard_time, :command_mode_timeout, :command_character, :node_discover_timeout, :node_identifier, :operation_mode, :api_mode, :transmission_mode
    attr_reader :serial_number, :hardware_rev, :firmware_rev
    
    VERSION = "2.1"

    def version
      VERSION
    end

    ##
    # This is the way we instantiate XBee modules now, via this factory method. It will ultimately autodetect what
    # flavor of XBee module we're using and return the most appropriate subclass to control that module.
    def initialize(xbee_usbdev_str, uart_config, operation_mode = :AT, transmission_mode = :SYNC)
      unless uart_config.kind_of?(XBeeUARTConfig)
        raise "uart_config must be an instance of XBeeUARTConfig for this to work"
      end
      unless operation_mode == :AT || operation_mode == :API
        raise "XBee operation_mode must be either :AT or :API"
      end
      unless transmission_mode == :SYNC || transmission_mode == :ASYNC
        raise "XBee transmission_mode must be either :SYNC (Synchronous) or :ASYNC (Asynchronous)"
      end
      self.xbee_uart_config = uart_config
      @xbee_serialport = SerialPort.new( xbee_usbdev_str, uart_config.baud, uart_config.data_bits, uart_config.stop_bits, uart_config.parity )
      @xbee_serialport.read_timeout = self.read_timeout(:short)
      @guard_time = GuardTime.new
      @command_mode_timeout= CommandModeTimeout.new
      @command_character = CommandCharacter.new
      @node_discover_timeout = NodeDiscoverTimeout.new
      @node_identifier = NodeIdentifier.new
      @operation_mode = operation_mode
      @api_mode = ApiEnableMode.new
      @transmission_mode = transmission_mode
    end

    def in_command_mode
      sleep self.guard_time.in_seconds
      @xbee_serialport.write(self.command_character.value * 3)
      sleep self.guard_time.in_seconds
      @xbee_serialport.read(3)
      # actually do some work now ...
      yield if block_given?
      # Exit command mode
      @xbee_serialport.write("ATCN\r")
      @xbee_serialport.read(3)
    end

    ##
    # XBee response times vary based on both hardware and firmware versions. These
    # constants may need to be adjusted for your devices, but these will
    # work fine for most cases.  The unit of time for a timeout constant is ms
    def read_timeout(type = :short)
      case type
        when :short
          1200
        when :long
          3000
        else 3000
      end
    end

    ##
    # a method for getting results from any Ruby SerialPort object. Not ideal, but seems effective enough.
    def getresults( sp, echo = false )
      results = ""
      while (c = sp.getc) do
        if ( !echo.nil? && echo )
          #putc c
        end
        results += "#{c.chr}"
      end

      # deal with multiple lines
      results.gsub!( "\r", "\n")
      puts results.unpack("H*") if echo
      results
    end

  end
end