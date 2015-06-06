require 'wavefile'
require 'curses'

require_relative 'models/jit_buffer'
require_relative 'models/stream'

module Radio
  class Client
    include WaveFile
    include Models

    def initialize(network)
      @network = network
      @network.add_data_listener(self)
      @gui = true ? ARGV[0] == "gui" : false
      @jit_buffer = JitBuffer.new(debug: !@gui)
      @stream = OutputStream.new(@jit_buffer)

      @format = Format.new(:mono, :pcm_16, 16_000)
      ui_init if @gui
    end


    def start
      @stream.open
      play
    end

    def close
      @stream.close
      @network.close
      Curses.close_screen
    end

    def play
      @stream.start
      @network.listening_thread.join
    end

    def handle(data)
      if data[:opcode] == 0
        @jit_buffer.buffer += data[:data]
        @title = data[:title]
        @radio_station = data[:radio_station]
      elsif data[:opcode] == 127
        puts "radio is off"
        close
      end
      refresh if @gui
    end

    def ui_init
      Curses.noecho
      Curses.stdscr.keypad(true)
      Curses.init_screen
      Curses.start_color

      Curses.init_pair(1, Curses::COLOR_WHITE,   Curses::COLOR_BLACK)
      Curses.init_pair(2, Curses::COLOR_RED,     Curses::COLOR_BLACK)
      Curses.init_pair(3, Curses::COLOR_YELLOW,  Curses::COLOR_BLACK)
      Curses.init_pair(4, Curses::COLOR_CYAN,    Curses::COLOR_BLACK)
      Curses.init_pair(5, Curses::COLOR_MAGENTA, Curses::COLOR_BLACK)
      Curses.init_pair(6, Curses::COLOR_GREEN,   Curses::COLOR_BLACK)

      @window = Curses::Window.new(10, 50, 0, 0)
    end

    def refresh
      @window.clear
      @window.attron(Curses.color_pair(3))
      @window.addstr "Jitter Buffer Size: #{@jit_buffer.size}\n"
      @window.attron(Curses.color_pair(5))
      @window.addstr "Current Track: #{@title}\n"
      @window.attron(Curses.color_pair(4))
      @window.addstr "Radio Station: #{@radio_station}\n"
      @window.refresh
    end
  end
end
