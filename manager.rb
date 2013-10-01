#!/usr/bin/env ruby

require_relative 'lib/communicator'

# This class works as a coordinator to dispatch orders
#
# Author::    Ivan Ramirez
class Coordinator
  include Communicator

  COORDINATOR_ROLE = "coordinator"

  def initialize host = "127.0.0.1", port = "5557"
    setup_communicator
    init_push_socket port
    init_pull_socket "*", port.to_i+1, true
    @acks = 0;
  end

  # You need to explicitly call this method when you are ready to receive messages
  def start
    @publisher = Thread.new do
          while true
            puts "Command? ";  #thread publishing commands
            publish $stdin.gets
          end
    end
    @reader = Thread.new { subscribe &Proc.new { |message| callback message } } #thread waiting for messages

    @publisher.join
  end

  def callback message
    if message == "ack"
      @acks += 1
      puts "Acks received: #{@acks}"
    end
  end

  def stop
    super

    Thread.kill(@publisher)
    Thread.kill(@reader)
  end

end

# This class connects to a coordinator a wait for orders
#
# Author::    Ivan Ramirez
class Worker
  include Communicator
  WORKER_ROLE = "worker"

  def initialize host = "127.0.0.1", port = "5557", publish_port = "5558"
    setup_communicator
    init_pull_socket host, port   #receives commands
    init_push_socket publish_port, false #pushes commands back in a not-blocking way by not binding to a port
  end

  # You need to explicitly call this method when you are ready to receive messages
  def start
    subscribe &Proc.new { |message| listener(message) }
  end

  # Call back method when a message is received
  def listener message
    p message
    case message.downcase
      # add own messages
      when "start"
        puts 'Starting'
      when "end"
        puts 'Ending'
        stop
        exit 0
      else
        puts "unknown message:#{message}"
    end
    publish "ack"
  end

end

# CLI tool to run example
#
# Author::    Ivan Ramirez
class Manager
  def initialize host, port, role
    workers = 0
    coordinators = 0;
    case role.downcase
      when Worker::WORKER_ROLE
        workers += 1
        puts 'New worker'
        worker = Worker.new host, port
        worker.start
      when Coordinator::COORDINATOR_ROLE
        coordinators += 1
        puts 'New coordinator'
        coordinator = Coordinator.new host, port
        coordinator.start
      else
        puts "Invalid role"
        exit -1
    end
  end
end

#------------------------------------------------------------------
# CLI tool to run example
#------------------------------------------------------------------
require 'optparse'

options = {}

optparse = OptionParser.new do|opts|
  opts.on( '-r', '--role STR', String, 'Application\'s role' ) do |setting|
    options[:role] = setting
  end

  options[:port] = "5557"
  opts.on( 'p', '--port STR', String, 'Port to connect to' ) do |setting|
    options[:port] = setting
  end

  options[:server] = "127.0.0.1"
  opts.on( 's', '--server STR', String, 'Server to connect to' ) do |setting|
      options[:server] = setting
  end

end

optparse.parse!

Manager.new options[:host], options[:port], options[:role]
