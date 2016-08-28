
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

    def Frame.new(source_io, api_mode = :API1)
      stray_bytes = []
      unless api_mode == :API1 or api_mode == :API2
        raise "XBee api_mode must be either :API1 (non-escaped) or :API2 (escaped, default)"
      end
      until (start_delimiter = source_io.readchar.unpack('H*').join.to_i(16)) == 0x7e
        #puts "Stray byte 0x%x" % start_delimiter
        print "DEBUG: #{start_delimiter} | " if $DEBUG
        stray_bytes << start_delimiter
      end
      if $VERBOSE
        puts "Got some stray bytes for ya: #{stray_bytes.map {|b| "0x%x" % b} .join(", ")}" unless stray_bytes.empty?
      end
      if(api_mode == :API1)
        header = source_io.read(3)
      elsif(api_mode == :API2)
        header = source_io.read(2).xb_unescape
      end
      print "Reading ... header after start byte: #{header.unpack("C*").join(", ")} | " if $DEBUG
      frame_remaining = frame_length = api_identifier = cmd_data = ""
      if api_mode == :API2
        if header.length == 2
          frame_length = header.unpack("n").first
        else
          read_extra_byte = source_io.readchar
          if(read_extra_byte == "\175")
            # We stumbled upon another escaped character, read another byte and unescape
            read_extra_byte += source_io.readchar
            read_extra_byte = read_extra_byte.xb_unescape
          else
            header += read_extra_byte
          end
          frame_length = header.unpack("n")
        end
        api_identifier = source_io.readchar
        if(api_identifier == "\175")
          api_identifier += source_io.readchar
          api_identifier = api_identifier.xb_unescape
        end
        api_identifier = api_identifier.unpack("C").first
      else
        frame_length, api_identifier = header.unpack("nC")
      end
      #### DEBUG ####
      if $DEBUG then
      print "Frame length: #{frame_length} | "
      print "Api Identifier: #{api_identifier} | "
      end
      #### DEBUG ####
      cmd_data_intended_length = frame_length - 1
      if api_mode == :API2
        while ((unescaped_length = cmd_data.xb_unescape.length) < cmd_data_intended_length)
          cmd_data += source_io.read(cmd_data_intended_length - unescaped_length)
        end
        data = api_identifier.chr + cmd_data.xb_unescape
      else
        while (cmd_data.length < cmd_data_intended_length)
          cmd_data += source_io.read(cmd_data_intended_length)
        end
        data = api_identifier.chr + cmd_data
      end
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
        when 0x81
          ReceivePacket16.new(data)
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

  end
end

require_relative 'base_frame'
require_relative 'received_frame'
require_relative 'at_command'
require_relative 'at_command_response'
require_relative 'explicit_addressing_command'
require_relative 'explicit_rx_indicator'
require_relative 'io_data_sample_rx_indicator'
require_relative 'modem_status'
require_relative 'receive_packet'
require_relative 'remote_command_request'
require_relative 'remote_command_response'
require_relative 'transmit_request'
require_relative 'transmit_status'
require_relative 'receive_packet_16'
