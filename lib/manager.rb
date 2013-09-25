#!/usr/bin/env ruby

require_relative 'communicator'
require_relative 'processhelper'

class Coordinator
  include Communicator
  include ProcessHelper

  COORDINATOR_ROLE = "coordinator"

  def initialize host = "127.0.0.1", port = "5557"
    setup
    start_ping_pong 1
    init_push_socket port
    init_pull_socket host, port.to_i+1
  end

  def start
    output = Thread.new { puts "Message? "; publish $stdin }
    input = Thread.new { subscribe &Proc.new { |message| callback message } }


    #input.run
    output.run
    input.join
  end

  def callback message
    puts "Server received #{message}"
  end

end

class Worker
  include Communicator
  WORKER_ROLE = "worker"

  def initialize host = "127.0.0.1", port = "5557", publish_port = "5558"
    setup
    init_pull_socket host, port
    init_push_socket publish_port
  end

  def start
    subscribe &Proc.new { |message| listener(message) }
  end

  def listener message
    case message.downcase
      when "start"
        puts 'Starting'
        publish "got it!"
      when "end"
        puts 'Ending'
      else
        puts "unknown message:#{message}"
    end
  end

end

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
        coordinator.publish "start"
        coordinator.start
      else
        puts "Invalid role"
        exit -1
    end
  end
end

#------------------------------------------------------------------
#------------------------------------------------------------------
require 'optparse'

options = {}

optparse = OptionParser.new do|opts|
  opts.on( '-r', '--role STR', String, 'Application\'s role' ) do |setting|
    puts setting
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
