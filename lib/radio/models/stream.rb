require 'ffi-portaudio'

module Radio
  module Models
    include FFI::PortAudio
    class OutputStream < Stream
      attr_accessor :buffer, :delay
      def initialize(buffer)
        @buffer = buffer
        init_pa
      end

      def process(input, output, frameCount, timeInfo, statusFlags, userData)
        output.write_array_of_int16(@buffer.get)
        :paContinue
      end

      def init_pa
        API.Pa_Initialize
        @output = API::PaStreamParameters.new
        @output[:device] = API.Pa_GetDefaultOutputDevice
        @output[:channelCount] = 1
        @output[:sampleFormat] = API::Int16
        @output[:suggestedLatency] = 0
        @output[:hostApiSpecificStreamInfo] = nil
      end

      def open
        super(nil, @output, 16_000, 800)
      end

      def close
        super
        API.Pa_Terminate
      end
    end
  end
end