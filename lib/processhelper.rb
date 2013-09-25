module ProcessHelper

  # Executes another task as a separate process
  # @param fire_and_forget Flag that decides whether to block or not until the subprocess is done
  # @param block to execute
  # @return if blocking until the process is done, returns the exit status. Otherwise null
  def create_task(fire_and_forget = true)
    # Fork process
    pid = fork do
      trap :INT do
        send :before_exit_hook if respond_to? :before_exit_hook
      end

      yield
      exit
    end

    # If we are waiting for the task to complete
    if !fire_and_forget
      pid, status = Process.wait2 pid
      return status.exitstatus
    else
      #else detach child from parent to avoid zombies
      Process.detach pid
    end

    pid
  end

end