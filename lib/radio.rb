require_relative 'radio/network'
require_relative 'radio/server'
require_relative 'radio/client'

module Radio
  def self.server_start(folder)
    network = Network.new
    server = Server.new(network, folder)

    Signal.trap('SIGINT') do
      server.close
      network.close
    end

    server.start
  end

  def self.client_start
    network = Network.new
    client = Client.new(network)

    Signal.trap('SIGINT') do
      client.close
      network.close
    end

    client.start
  end
end