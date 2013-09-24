$: << File.dirname(__FILE__)

class String
  def xb_escape
    self.gsub(/[\176\175\021\023]/) { |c| [0x7D, c[0].ord ^ 0x20].pack("CC")}
  end
  def xb_unescape
    self.gsub(/\175./) { |ec| [ec.unpack("CC").last ^ 0x20].pack("C")}
  end
end

module XBee
  module Frame
    def Frame.checksum(data)
      0xFF - (data.unpack("C*").inject(0) { |sum, byte| (sum + byte) & 0xFF })
    end

    def Frame.new(source_io)
      stray_bytes = []
      until (start_delimiter = source_io.readchar.unpack('H*').join.to_i(16)) == 0x7e
        #puts "Stray byte 0x%x" % start_delimiter
        print "DEBUG: #{start_delimiter} | " if $DEBUG
        stray_bytes << start_delimiter
      end
      puts "Got some stray bytes for ya: #{stray_bytes.map {|b| "0x%x" % b} .join(", ")}" unless stray_bytes.empty?
      header = source_io.read(3).xb_unescape
      print "Reading ... header after start byte: #{header.unpack("C*").join(", ")} | " if $DEBUG
      frame_remaining = frame_length = api_identifier = cmd_data = ""
      if header.length == 3
        frame_length, api_identifier = header.unpack("nC")
      else
        frame_length, api_identifier = header.unpack("n").first, source_io.readchar
      end
      #### DEBUG ####
      if $DEBUG then
      print "Frame length: #{frame_length} | "
      print "Api Identifier: #{api_identifier} | "
      end
      #### DEBUG ####
      cmd_data_intended_length = frame_length - 1
      while ((unescaped_length = cmd_data.xb_unescape.length) < cmd_data_intended_length)
        cmd_data += source_io.read(cmd_data_intended_length - unescaped_length)
      end
      data = api_identifier.chr + cmd_data.xb_unescape
      sent_checksum = source_io.getc.unpack('H*').join.to_i(16)
      #### DEBUG ####
      if $DEBUG then
      print "Sent checksum: #{sent_checksum} | "
      print "Received checksum: #{Frame.checksum(data)} | "
      print "Payload: #{cmd_data.unpack("C*").join(", ")} | "
      end
      #### DEBUG ####
      unless sent_checksum == Frame.checksum(data)
        raise "Bad checksum - data discarded"
      end
      case data[0].unpack('H*')[0].to_i(16)
        when 0x8A
          ModemStatus.new(data)
        when 0x88 
          ATCommandResponse.new(data)
        when 0x97 
          RemoteCommandResponse.new(data)
        when 0x8B 
          TransmitStatus.new(data)
        when 0x90 
          ReceivePacket.new(data)
        when 0x91 
          ExplicitRxIndicator.new(data)
        when 0x92
          IODataSampleRxIndicator.new(data)
        else
          ReceivedFrame.new(data)
      end
      rescue EOFError
        # No operation as we expect eventually something
    end

    class Base
      attr_accessor :api_identifier, :cmd_data, :frame_id

      def api_identifier ; @api_identifier ||= 0x00 ; end

      def cmd_data ; @cmd_data ||= "" ; end

      def length ; data.length ; end

      def data
        Array(api_identifier).pack("C") + cmd_data
      end

      def _dump
        raise "Too much data (#{self.length} bytes) to fit into one frame!" if (self.length > 0xFFFF)
        "~" + [length].pack("n").xb_escape + data.xb_escape + [Frame.checksum(data)].pack("C")
      end
    end

    class ReceivedFrame < Base
      def initialize(frame_data)
        # raise "Frame data must be an enumerable type" unless frame_data.kind_of?(Enumerable)
        self.api_identifier = frame_data[0]
        if $DEBUG then
          print "Initializing a ReceivedFrame of type 0x%x | " % self.api_identifier.unpack('H*').join.to_i(16)
        else
          puts "Initializing a ReceivedFrame of type 0x%x" % self.api_identifier.unpack('H*').join.to_i(16)
        end
        self.cmd_data = frame_data[1..-1]
      end
    end
  end
end

require 'at_command'
require 'at_command_response'
require 'explicit_addressing_command'
require 'explicit_rx_indicator'
require 'io_data_sample_rx_indicator'
require 'modem_status'
require 'receive_packet'
require 'remote_command_request'
require 'remote_command_response'
require 'transmit_request'
require 'transmit_status'

