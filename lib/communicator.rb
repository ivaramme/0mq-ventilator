# This module implements behaviors used by objects that communicate between each other using the 0mq library
#
# Author::    Ivan Ramirez
module Communicator
  require 'ffi-rzmq'
  require 'logger'

  # Misc setup
  def setup_communicator
    Signal.trap(:INT) do
      stop
    end
  end

  # Initializes a ventilator socket (push)
  def init_push_socket port, bind_all = true, publish_to_host = "localhost"
    context = ZMQ::Context.new 1
    @push = context.socket(ZMQ::PUSH)

    if bind_all
      @push.bind("tcp://*:"+port)  #publish to anyone listening
      Communicator::get_logger.info "Binding to port #{port}"
    else
      @push.connect "tcp://#{publish_to_host}:#{port}" #connects pusher socket to a binding socket
      Communicator::get_logger.info "Connecting pusher to host #{publish_to_host} port #{port}"
    end
  end

  # Initializes a listener socket (pull) that connects to the ventilator
  def init_pull_socket host, port, bind_all = false
    context = ZMQ::Context.new 1
    @pull = context.socket(ZMQ::PULL)

    if !bind_all
      @pull.connect "tcp://#{host}:#{port}" #connect to a publisher socket
      Communicator::get_logger.info "Connecting to tcp://#{host}:#{port}"
    else
      @pull.bind "tcp://*:#{port}" #listen for a publisher in this port
      Communicator::get_logger.info "Binding to tcp://*:#{port}"
    end

  end

  # Publishes messages through the push socket
  # Params:
  # +message+:: String with the message
  def publish message
    return if @push.nil?
    response = @push.send_string message #block until there's a connection
    Communicator::get_logger.info "Error sending message, code #{response}" if error?(response)
  end

  # Connects to a ventila messages through the push socket
  # Params:
  # +handler+:: optional block to handle a received message
  def subscribe &handler
    input = ""
    response = 0
    #wait for message from pull socket
    while true
      response = @pull.recv_string(input)
      if !error?(response)
        input.chomp!

        #Message received
        yield input if block_given?
        Communicator::get_logger.info "Message received: #{input}"
      end
    end
  end

  # Returns true if the response code is an error
  # +response+:: response code from socket
  def error? response
    return false if ZMQ::Util.resultcode_ok?(response)
    Communicator::get_logger.error "Operation failed, errno [#{ZMQ::Util.errno}] description [#{ZMQ::Util.error_string}]"
    true
  end

  # Stops threads and close sockets gracefully
  def stop
    @pull.close if !@pull.nil?
    @push.close if !@push.nil?
    Communicator::get_logger.info "Forcing app to shut down"
    exit 0
  end

  def self.get_logger
    @@log ||= Logger.new "log.txt"
    @@log
  end

end