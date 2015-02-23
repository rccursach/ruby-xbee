#!/usr/bin/env ruby
$: << File.dirname(__FILE__)

require 'date'
require 'ruby-xbee'
require 'pp'

@uart_config = XBee::Config::XBeeUARTConfig.new()
@xbee = XBee::BaseAPIModeInterface.new(@xbee_usbdev_str, @uart_config)

# read XBee output forever
while 1
  @xbee.getresponse true
end
