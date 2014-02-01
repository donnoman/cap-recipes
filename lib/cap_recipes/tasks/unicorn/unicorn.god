# http://unicorn.bogomips.org/SIGNALS.html

rails_env = "<%=rails_env%>"
rails_root = "<%=unicorn_root%>"
group_name = "<%=unicorn_god_group_name%>"

God.watch do |w|
  w.group = group_name
  w.name = "<%=unicorn_god_name%>"
  w.interval = 10.seconds # 30 default
  w.env = {
    'UNICORN_WORKERS' =>  '<%=unicorn_workers%>'
  }

  # unicorn needs to be run from the rails root
  w.start = "cd #{rails_root} && <%=base_ruby_path%>/bin/bundle exec unicorn -c #{rails_root}/config/unicorn.rb -E #{rails_env} -D"

  # QUIT gracefully shuts down workers
  w.stop =  "kill -QUIT `cat #{rails_root}/tmp/pids/unicorn.pid`"

  # USR2 causes the master to re-create itself and spawn a new worker pool
  w.restart = "kill -USR2 `cat #{rails_root}/tmp/pids/unicorn.pid`"

  w.start_grace = <%=unicorn_god_start_grace%>.seconds
  w.restart_grace = <%=unicorn_god_restart_grace%>.seconds
  w.stop_grace = <%=unicorn_god_stop_grace%>.seconds
  w.stop_timeout = <%=unicorn_god_stop_timeout%>.seconds

  w.pid_file = "#{rails_root}/tmp/pids/unicorn.pid"

  w.uid = '<%=unicorn_user%>'
  w.gid = '<%=unicorn_group%>'

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
