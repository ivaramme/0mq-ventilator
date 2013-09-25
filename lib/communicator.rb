module Communicator
  require 'ffi-rzmq'
  require 'logger'

  def publish message
    #puts "sending #{message}"
    response = @push.send_string message #block until there's a connection

    Communicator::get_logger.debug "Error sending message, code #{response}" if error?(response)
  end

  def subscribe &handler
    input = ""
    response = 0
    while ZMQ::Util.resultcode_ok?(response)
      response = @pull.recv_string(input)
      if !error?(response)
        if input.downcase == "ping"
          #puts "received ping from #{@pull}"
          @pings += 1
          puts "Pings received: #{@pings}" if @pings % 100 == 0
          pong
          next
        end

        next if input.downcase == "pong"

        yield input if block_given?
        Communicator::get_logger.info "Message received: #{input}"
      end
    end
  end

  def error? response
    return false if ZMQ::Util.resultcode_ok?(response)

    Communicator::get_logger.error "Error sending message, code #{response}" if error?(response)
    puts "Operation failed, errno [#{ZMQ::Util.errno}] description [#{ZMQ::Util.error_string}]"
    true
  end

  def init_push_socket port
    context = ZMQ::Context.new 1
    @push = context.socket(ZMQ::PUSH)
    @push.bind("tcp://*:"+port)

    Communicator::get_logger.info "Binding to port #{port}"
  end

  def init_pull_socket host, port
    context = ZMQ::Context.new 1
    @pull = context.socket(ZMQ::PULL)
    @pull.connect "tcp://#{host}:#{port}"

    Communicator::get_logger.info "Connecting to tcp://#{host}:#{port}"
  end

  def self.get_logger
    @@log ||= Logger.new "log.txt"
    @@log
  end

  def stop
    Thread.kill(@ping_pong) if !@ping_pong.nil?
    @pull.close if !@pull.nil?
    @push.close if !@push.nil?
    Communicator::get_logger.debug "Forcing app to shut down"
    exit 0
  end

  def setup
    Signal.trap(:INT) do
      stop
    end
    @pings = 0;
  end

  def start_ping_pong timeout = 1
    @ping_pong = Thread.new {
                              while true
                                ping
                                sleep timeout
                              end
    }
    @ping_pong.run
  end

  def ping
    publish "ping" if !@push.nil?
  end

  def pong
    publish "pong" if !@push.nil?
  end

end