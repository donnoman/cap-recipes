God.watch do |w|
  w.name = "newrelic-sysmond"
  w.group = "newrelic"
  w.interval = 30.seconds
  w.start = "/etc/init.d/newrelic-sysmond start"
  w.stop = "/etc/init.d/newrelic-sysmond force-stop"
  w.pid_file = "/var/run/newrelic/nrsysmond.pid"

  w.start_grace = 30.seconds
  w.restart_grace = 30.seconds
  w.stop_grace = 30.seconds

  # Make sure the pid directory exists
  FileUtils.mkdir_p File.dirname(w.pid_file)

  # clean pid files before start if necessary
  w.behavior(:clean_pid_file)

  # determine the state on startup
  w.transition(:init, { true => :up, false => :start }) do |on|
    on.condition(:process_running) do |c|
      c.running = true
    end
  end

  # determine when process has finished starting
  w.transition([:start, :restart], :up) do |on|
    on.condition(:process_running) do |c|
      c.running = true
    end
  end

  # start if process is not running
  w.transition(:up, :start) do |on|
    on.condition(:process_exits) do |c|
      c.notify = %w[ <%=god_notify_list%> ]
    end
  end

  # lifecycle
  w.lifecycle do |on|
    on.condition(:flapping) do |c|
      c.to_state = [:start, :restart]
      c.times = 5
      c.within = 5.minute
      c.transition = :unmonitored
      c.retry_in = 10.minutes
      c.retry_times = 5
      c.retry_within = 2.hours
      c.notify = %w[ <%=god_notify_list%> ]
    end
  end
end