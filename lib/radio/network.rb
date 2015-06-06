require 'socket'
require 'ipaddr'
require 'bindata'

module Radio
  class SRSP < BinData::Record
    # opcode = 0, sending audio samples
    # opcode = 127, stop

    uint8le  :opcode
    uint8le  :radio_station
    uint16le :seq_num, :onlyif => :stream?
    uint16le :len, :value => lambda { title.length }, :onlyif => :stream?
    string   :title, :read_length => :len, :onlyif => :stream?
    array    :data,
             :type => :int16le,
             :initial_length => 200,
             :onlyif => :stream?

    def stream?
      opcode == 0
    end
  end

  class Network
    attr_reader :listening_thread
    PORT = 3000
    MULTICAST_ADDR = "230.1.1.128"

    def initialize
      @ip = IPAddr.new(MULTICAST_ADDR).hton + IPAddr.new("0.0.0.0").hton
      @port = PORT
      @socket = UDPSocket.new
      @socket.setsockopt(Socket::IPPROTO_IP, Socket::IP_ADD_MEMBERSHIP, @ip)

      @listeners = []
      @listening = false

      @protocol = SRSP.new
      @protocol.radio_station = 255

      @seq_counter = 0
    end

    def add_data_listener(listener)
      listen unless listening?
      @listeners << listener
    end

    def listen
      @socket.bind(Socket::INADDR_ANY, @port)

      @listening_thread = Thread.new do
        loop do
          raw_data = @socket.recvfrom(1500)[0]
          data = @protocol.read(raw_data)

          @listeners.each do |listener|
            listener.handle(data)
          end
        end
      end

      @listening = true
    end

    def listening?
      @listening == true
    end

    def close
      @listening_thread.kill if listening?
      @socket.close
    end

    def send_audio(title, samples)
      @protocol.data = samples
      @protocol.seq_num = @seq_counter
      @protocol.title = title
      @socket.send(@protocol.to_binary_s, 0, MULTICAST_ADDR, @port)
      @seq_counter += 1
      @seq_counter = 0 if @seq_counter == 65535
    end

    def send_stop
      @protocol.opcode = 127
      @socket.send(@protocol.to_binary_s, 0, MULTICAST_ADDR, @port)
      puts @protocol
    end
  end
end