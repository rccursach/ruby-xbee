require "ruxbee/version"
require "ruxbee/config"
require "ruxbee/xbee_api"
require "ruxbee/xbee_cmd"

module Ruxbee

  ##
  # creates a new instance on Command or API mode
  # mode is a Symbol, either :API_S1, :API_S2 or :CMD
  def XBee.new(dev_str, baud, mode, operation_mode = :API)
    # check for valid mode descriptor
    unless mode.is_a? Symbol and (mode == :API_S1 or mode == :API_S2 or mode == :CMD)
      raise "Not a valid mode, choose :API_S1, :API_S2 or :CMD"
    end

    unless operation_mode.is_a? Symbol and (operation_mode == :API or operation_mode == :AT)
      raise "Not a valid operation_mode, choose :API or :AT"
    end
    
    # defaults to: data_bits = 8, parity = 0, stop_bits = 1
    uart_conf = XBee::Config::XBeeUARTConfig.new(baud)

    case mode
    when :API_S1
      XBee::Series1APIModeInterface.new(dev_str, uart_conf, operation_mode)
    when :API_S2
      XBee::Series2APIModeInterface.new(dev_str, uart_conf, operation_mode)
      # Series2APIModeInterface.new(dev_str, uart_conf, operation_mode, transmission_mode = :SYNC)
    when :CMD
      XBee::BaseCommandModeInterface.new(dev_str, uart_conf.baud, uart_conf.data_bits, uart_conf.stop_bits, uart_conf.parity)
    else
      raise "Unknown Exception, no mode was found"
    end
  end

end
