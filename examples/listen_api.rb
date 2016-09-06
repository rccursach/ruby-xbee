#!/usr/bin/env ruby

require "bundler/setup"
require "ruxbee"
require 'pp'
require 'getoptlong'


opts = GetoptLong.new(
  [ '--device', '-d', GetoptLong::REQUIRED_ARGUMENT ],
  [ '--speed', '-s', GetoptLong::REQUIRED_ARGUMENT ]
)

@dev = nil
@speed = nil

opts.each do |opt, arg|
 case opt
 when '--device'
   @dev = arg
 when '--speed'
   @speed = arg.to_i
 end 
end

@xbee = XBee.new @dev, @speed, :API_S1

loop do
  res = @xbee.getresponse
  if not res.nil? and res.api_identifier == '81'
    res = {rssi: res.rssi, address: res.address_16_bits, api_frame_id: res.api_identifier, data: res.cmd_data}
    pp res
  end
end

