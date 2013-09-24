module XBee
  module Frame
    class IODataSampleRxIndicator < ReceivedFrame
      def cmd_data=(data_string)

        @cmd_data = data_string
      end
    end
  end
end