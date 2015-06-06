require 'wavefile'

require_relative 'models/jit_buffer'
require_relative 'models/stream'

module Radio
  class Server
    include WaveFile
    include Models

    def initialize(network, folder)
      @network = network
      @jit_buffer = JitBuffer.new
      @stream = OutputStream.new(@jit_buffer)

      @format = Format.new(:mono, :pcm_16, 16_000)
      @folder = folder
    end


    def start
      play
    end

    def close
      @stream.close
    end

    def play
      folder = Dir.new(@folder)
      folder.each do |file|
        if /.+.wav/.match file
          puts "Current Track: #{file}"
          Reader.new("music/#{file}", @format).each_buffer(200) do |buffer|
            time = Time.now
            @network.send_audio(file, buffer.samples)
            sleep (0.0112 - (Time.now - time)).abs
          end
        end
      end

      @network.send_stop
    end
  end
end
