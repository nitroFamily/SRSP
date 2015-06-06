module Radio
  module Models
    class JitBuffer
      attr_accessor :buffer, :buffer_delay
      def initialize(debug: false)
        @buffer = []
        @debug = debug
      end

      def get
        if @buffer.size >= 800
          print @buffer.size if @debug
          samples = @buffer[0,800]
          @buffer.slice!(0, 800)

          puts " - #{@buffer.size}" if @debug
        else
          samples = [0] * 800
        end

        samples
      end

      def method_missing(m, *args, &block)
        @buffer.send(m, *args, &block)
      end

    end
  end
end