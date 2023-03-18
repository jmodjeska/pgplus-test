require_relative './strings.rb'
require 'net-telnet'
require 'net/ssh'
require 'yaml'

CONFIG = YAML.load_file('config/config.yaml')
LOG = 'data/output.log'

private def noisy(str)
  puts str if CONFIG.dig('verbose_mode')
end

private def cfg(profile, key)
  return CONFIG.dig('profiles', profile, key)
end

class ConnectTelnet
  def initialize(section, profile)
    @section = section
    @profile = profile
    @username = cfg(@profile, 'username')
    @ip = cfg(@profile, 'ip')
    @port = cfg(@profile, 'port')
    puts "-=> Testing section: #{@section}".bold.blue
    @client = new_client
  end

  def new_client
    File.truncate(LOG, 0) if File.exist?(LOG)
    begin
      client = Net::Telnet::new(
        "Host" => @ip,
        "Port" => @port,
        "Prompt" => /#{cfg(@profile, 'prompt')} \z/n,
        "Binmode" => true,
        "Telnetmode" => true,
        "Timeout" => 3,
        "Output_log" => LOG
      )
    rescue Errno::EHOSTUNREACH, Net::OpenTimeout => e
      abort "Can't reach #{@ip} at port #{@port}\n".failure
    rescue Errno::ECONNREFUSED => e
      abort "Connection refused to #{@ip} at port #{@port}. "\
        "Is the talker running?\n".failure
    end

    # Validate connection
    result = IO.readlines(LOG)[1].chomp!
    unless result == "Connected to #{@ip}."
      abort "Talker connection failed (result: #{result})".failure
    end

    # Login + validation
    client.puts(@username)
    fork do
      sleep 1
      if system("grep 'try again!' #{LOG} > /dev/null") then
        puts "Talker login failed (password) for #{@username}".failure
      elsif system("grep 'already logged on here' #{LOG} > /dev/null")
        noisy("Talker login successful for #{@username} "\
          "(NOTE: user was already logged in)".login)
        client.puts('')
      elsif system("grep 'Last logged in' #{LOG} > /dev/null")
        noisy("Talker login successful for #{@username}".login)
      else
        puts "Talker login failed for #{@username.bold} (see #{LOG})".failure
      end
    end
    client.cmd(cfg(@profile, 'password'))
    sleep 1 # Avoid exit before forked process completes
    return client
  end

  def send(cmd)
    stack = ''
    @client.cmd(cmd) { |o| stack << o }
    return stack
  end

  def done
    @client.cmd("quit")
    sleep 0.1
    if system("grep 'Thanks for visiting' #{LOG} > /dev/null") then
      noisy("Talker logout successful for #{@username}".logout)
    end
    puts "\n"
  end
end

class ConnectSSH
  def initialize()
    @ssh_user = cfg('ssh_user', 'username')
    @ssh_host = cfg('ssh_user', 'ssh_host')
    @pem_file = cfg('ssh_user', 'pem_file')
  end

  def send(cmd)
    test_name = caller_locations.first.base_label
    stack = ''
    begin
      Net::SSH.start( @ssh_host, @ssh_user, keys: @pem_file ) do |ssh|
      rescue Net::SSH::AuthenticationFailed => e
        puts "SSH login failed #{@ssh_user}@#{@ssh_host}".failure
      rescue SocketError
        puts "SSH host #{@ssh_host} not reachable".failure
      else
        noisy("SSH login successful for #{@ssh_user}@#{@ssh_host}: ".login)
        # Single command
        if cmd.kind_of? String then
          noisy("#{cmd}".wrap(6))
          stack = ssh.exec!(cmd) if cmd.kind_of? String
        end
        # Hash of commands
        # (values, as commands, get replaced with their output)
        if cmd.kind_of? Hash then
          noisy("(#{cmd.length} commands)".wrap(6))
          puts "Testing #{test_name.bold} ...".waiting
          i, l, stack = 1, cmd.length, {}
          cmd.each do |c, v|
            printf("%7sChecking %4i of %4i", ' ', i, l)
            cmd[c] = ssh.exec!(v)
            print "\b" * 28
            i += 1
          end
          print " " * 28
          stack = cmd
        end
      end
      # Net::SSH closes the connection when the block terminates
      noisy("SSH connection closed".logout)
    end
    return stack
  end
end
