#!/usr/bin/env ruby
#
# Programmable XBee module Over the Air (OTA) Upgrade
# A sample using ruby-xbee and xmodem.
#
# Please note, this only works for PROGRAMMABLE XBee modules and for uploading
# the *application* firmware, not to be confused with the radio firmware.
#
# The coordinator must be running in API 1 mode because the programmable XBEE
# does not properly in the API mode 2 (with escaped control characters).
#
# This is specific to Series 2 radios and ZigBee
#
# This script is not interactive, please define the below CONSTANTS before use
#
# If you are using broadcast addresses, make sure only one device is there to
# answer, concurrent upgrades have not been implemented
#
# Prerequisites: Install the xmodem gem by: gem install xmodem it's purposely
# left out from runtime dependencies.
#
# Usage: 1) set the constants
#        2) make sure the ruby-xbee.rb has the correct device configured
#        3) ./ota_upgrade.rb
#
$: << File.dirname(__FILE__)

require 'date'
require 'ruby-xbee'
require 'pp'
require 'socket'

require 'rubygems'
gem 'xmodem'
require 'xmodem'

### CONSTANTS - SET BEFORE USE

# Target Address of the device being upgraded 0x000000000000FFFF for broadcast
TARGET_ADDRESS = 0x000000000000FFFF
# Target network, 0xFFFE for broadcast
TARGET_NETWORK = 0xFFFE
# OTA password, nil, if no password used
PASSWORD = nil
# Firmware file being uploaded, can be full path
TRANSFER_FILE = "blink_led_0_0_1_OTA_blank_pass.bin"
# If not on unix, this is the port used for XMODEM IO
LOCAL_PORT = 2000

### END OF CONSTANTS

@uart_config = XBee::Config::XBeeUARTConfig.new()
@xbee = XBee::Series2APIModeInterface.new(@xbee_usbdev_str, @uart_config)

# Create server/socket for XModem transfer
@server=nil
@unix_socket = "/tmp/xmodem-transfer.sock"

# State variables
@transfer_started = false
@transfer_eot = 0

if !FileTest.exists?(TRANSFER_FILE)
  puts "Firmware file not found: #{TRANSFER_FILE}"
  exit
end

if ENV['OS'] != "Windows_NT"
  File.delete( @unix_socket ) if FileTest.exists?( @unix_socket )
  @server = UNIXServer.new(@unix_socket)
else
  @server = TCPServer.new(LOCAL_PORT)
end

puts "---------------------------------------------------"
puts "             Over The Air Upgrade                  "
puts "---------------------------------------------------"
puts "Target address: 0x%x" % TARGET_ADDRESS
puts "Target network: 0x%x" % TARGET_NETWORK
puts "---------------------------------------------------"

#XMODEM::logger.outputters = Outputter.stdout
XMODEM::timeout_seconds = 10.0 # Let's prolong the timeout
XMODEM::block_size      = 64   # XBEE uses non-standard block size

puts "XMODEM: Transfer blocksize: #{XMODEM::block_size}"
puts "XMODEM: Timeout in seconds: #{XMODEM::timeout_seconds}"

transfer_thread = Thread.new {
  session = @server.accept
  session.sync = true
  file = File.new(TRANSFER_FILE, "rb")
  puts "Starting file transfer of: #{TRANSFER_FILE}"
  XMODEM::send(session, file)
  session.close
  puts "<CLOSED>"
  file.close
}

##
# If the target board does not have proper OTA enabled application running
# or if the previous upgrades have been unsuccessful to the point where the
# module is unable to run and goes to bootloader, the following method
# can be used instead of the init_ota_upgrade. If the application is running
# the following request does not get any response
#
# Please note that the following works only if the target is in bootloader and
# when explicit addressing is used (broadcast address doesn't work, altough
# the target network can be broadcast)!
frame_id = @xbee.next_frame_id
frame_to_send = XBee::Frame::ExplicitAddressingCommand.new(frame_id, TARGET_ADDRESS, TARGET_NETWORK, 0xE8, 0xE8, 0x0011, 0xC105, 0x00, 0x00, "F")
@xbee.xbee_serialport.write(frame_to_send._dump)

##
# The following call is meant for Applications that have the OTA upgrade
# enabled. In case of wrong password a "bad password" message is sent in reply
#
# Let's send a initialization package for starting OTA upgrade
@xbee.init_ota_upgrade(PASSWORD, TARGET_ADDRESS, TARGET_NETWORK)

# main loop
while 1
  begin

    r = @xbee.getresponse true

    if r.kind_of?(XBee::Frame::ExplicitRxIndicator) and r.cluster_id == 0x0011 and r.profile_id == 0xC105
      if !@transfer_started and r.received_data == "C"
        puts "XBEE: Got response with frame type: 0x%02x" % r.api_identifier
        puts "XBEE: Source address of the one waiting for new firmware: %x" % r.source_address
        # Connect to socket
        if ENV['OS'] != "Windows_NT"
          socket = UNIXSocket.open(@unix_socket)
        else
          socket = TCPSocket.new('localhost', LOCAL_PORT)
        end
        socket.sync=true
        @transfer_started = true
        puts "Connected to socket"
        sleep(0.1)
      end

      if r.received_data == "C"
        print "C"
      elsif r.received_data.ord == XMODEM::ACK
        print "O"
      elsif r.received_data.ord == XMODEM::NAK
        print "X"
      elsif r.received_data == "F" and !@transfer_started
        puts "F - Upgrade started from bootloader"
        next
      else
        print "?"
      end

      unless socket.closed?
        # As we have the socket open, we can presume the tranmission is ok to
        # start.
        if transfer_thread.alive? and @transfer_eot < 1
          # Send the received payload to local XMODEM socket
          socket.write(r.received_data)

          # Try to get the block that the XMODEM wants to send
          # 3 header bytes, data block, 2 bytes checksum
          # We read the first byte separately in case it's the end of file
          data_to_send = ""
          b = XMODEM::receive_getbyte(socket)
          data_to_send << b

          if data_to_send.ord == XMODEM::SOH
            (XMODEM::block_size+4).times do
              b = XMODEM::receive_getbyte(socket)
              data_to_send << b
            end
          elsif data_to_send.ord == XMODEM::EOT
            print "<END-OF-TRANSMISSION>"
            @transfer_eot += 1
          end

          #puts "Inspecting packet to encapsulate: #{data_to_send.inspect}"

          # We have the XMODEM block, we should encapsulate and send it to the radio
          frame_id = @xbee.next_frame_id
          frame_to_send = XBee::Frame::ExplicitAddressingCommand.new(frame_id, r.source_address, r.source_network, 0xE8, 0xE8, 0x0011, 0xC105, 0x00, 0x00, data_to_send)
          @xbee.xbee_serialport.write(frame_to_send._dump)
          print "."
        else
          # Transfer completed
          socket.close
          puts "XBEE: Transfer completed!"
          break
        end
      end
    elsif r.kind_of?(XBee::Frame::ExplicitRxIndicator) and r.cluster_id == 0x1000 and r.profile_id == 0xC105 and r.received_data == "bad password"
      puts "XBEE: Bad password sent for device: 0x%x. Giving up." % r.source_address
      break
    end

    if r.kind_of?(XBee::Frame::TransmitStatus)
      #puts "XBEE: Got response with frame type: 0x%02x" % r.api_identifier
      #puts "XBEE: cmd_data: #{r.cmd_data.inspect}"
    end

  rescue RuntimeError => e
    puts e
  end
end

unless ENV['OS'] == "Windows_NT"
  File.delete( @unix_socket ) if FileTest.exists?( @unix_socket )
end

puts "Exiting!"
