require 'yaml'
require 'numbers_in_words'

STUBS = YAML.load_file('data/stubs.yaml')
TEMP = 'pgplus-test_temp.txt'

module Tests

  private def clean(i)
    # Remove ANSI color codes and newlines from a string
    # (recommended for all 'actual' result comparisons)
    o = i.gsub(/\e\[([;\d]+)?m/, '').strip
    o.delete!("^\u{0000}-\u{007F}")
    return o
  end

  private def check_stub(cmd)
    if STUBS[cmd].nil? then
      message = "A stub for `#{cmd}` seems to be missing"
      return [false, [:results, false, 'stub', message]]
    else return [true]
    end
  end

  def toggle_pager(h, desired_state)
    2.times do
      o = clean(h.send('nopager')).lines[0]
      state = o.match?("You will not") ? 'unpaged' : 'paged'
      return true if state == desired_state
    end
    return false
  end

  # Comparison tests return arrays as follows
  # 0: :results to identify the report type
  # 1: Pass (True/False)
  # 2: Expected
  # 3: Actual

  # BASIC COMMAND TESTS

  def top_line_matches(cmd, out)
    return check_stub(cmd)[1] unless check_stub(cmd)[0]
    expected = STUBS[cmd].lines.first.strip
    actual = clean(out.lines.first)
    return [:results, expected == actual, expected, actual]
  end

  def first_row_of_table_matches(cmd, out)
    return check_stub(cmd)[1] unless check_stub(cmd)[0]
    expected = STUBS[cmd].lines[1].strip
    actual = clean(out.lines[1])
    return [:results, expected == actual, expected, actual]
  end

  def line_matches(cmd, out, num)
    return check_stub(cmd)[1] unless check_stub(cmd)[0]
    i = num[0]
    expected = clean(STUBS[cmd].lines[i])
    actual = clean(out.lines[i])
    return [:results, expected == actual, expected, actual]
  end

  def bottom_line_matches(cmd, out)
    return check_stub(cmd)[1] unless check_stub(cmd)[0]
    expected = STUBS[cmd].lines.last.strip
    actual = clean(out.lines[-2])
    return [:results, expected == actual, expected, actual]
  end

  def bottom_line_contains(cmd, out, match)
    m = Regexp.new match[0]
    actual = out.lines[-2].strip
    expected = "#{actual} contains #{m.to_s}"
    return [:results, m.match?(actual), expected, actual]
  end

  def all_lines_match(cmd, out)
    return check_stub(cmd)[1] unless check_stub(cmd)[0]
    expects = {}
    STUBS[cmd].lines[0..-1].each_with_index do |l, i|
      expects[clean(l)] = clean(out.lines[i])
    end
    passfail = expects.all? { |k, v| k == v }
    diff = expects.select { |k, v| k != v }
    return [:results, passfail, "all lines match", output_hash(diff)]
  end

  def social(cmd, out, str=nil)
    return check_stub(cmd)[1] unless check_stub(cmd)[0]
    expected = [STUBS[cmd].lines.first.strip]
    actual = out.lines.first.strip
    # Parse as many embedded variables {a|b|c} as needed to create
    # an array of each possible social variant
    expected[0].scan(/(?=\{)/).count.times do |i|
      r = "{(.*?)}"
      m = expected[0].match /#{r}/
      arr = m[1].split('|')
      v = expected.length
      arr.each do |word|
        v.times do |var_counter|
          expected << (expected[var_counter].sub /{(.*?)}/, word)
        end
      end
      v.times { expected.shift }
    end
    return [:results, expected.include?(actual), expected, actual]
  end

  # OTHER TESTS (NON-ADMIN)

  def check_known_admin_profile(h, args)
    return check_stub('check_known_admin_profile')[1] unless
      check_stub('check_known_admin_profile')[0]
    toggle_pager(h, "unpaged")
    stub = STUBS['check_known_admin_profile']
    out = clean(h.send("f #{args[0]}"))
    expects = {}

    # Login time
    ltime_stub = stub.lines[0].match(/^.*?(\d+).*?days/)[1].to_i
    ltime_out = out.lines[5].match(/^.*?(\d+).*?days/)[1].to_i
    if ltime_out >= ltime_stub then
      expects['login time >= stub'] = true
    else
      a = "stub: #{ltime_stub}; actual: #{ltime_out}"
      expects['login time >= stub'] = a
    end

    # WWW homepage
    if clean(stub.lines[1]) == clean(out.lines[12])
      expects['www homepage matches'] = true
    else
      expects['www homepage matches'] =
        "\nexpected: " + clean(stub.lines[1]) +
        "\nactual:   " + clean(out.lines[12])
    end
    passfail = expects.values.all? { |x| x == true }
    return [:results, passfail, "all true", output_hash(expects)]
  end

  # ADMIN & FILESYSTEM TESTS

  def backup_complete(h)
    return check_stub('backup')[1] unless check_stub('backup')[0]
    expected = STUBS['backup'].lines.last.strip
    actual = clean(h.send('backup').lines[-2])
    return [:results, expected == actual, expected, actual]
  end

  def backup_file_generated(h, ssh, backup_path)
    cmd1 = "[ -e #{backup_path[0]} ] && echo \"true\" || echo \"false\""
    cmd2 = "[ -e #{backup_path[1]} ] && echo \"true\" || echo \"false\""
    o1 = ssh.send(cmd1).strip
    o2 = ssh.send(cmd2).strip
    return [:results, [o1, o2].any?("true"), "any true", [o1, o2]]
  end

  def mlink(h, ssh, args)
    # Expected args:
    # [0]: link to create
    # [1] path to logrotate or fixlog
    # [2] path to links.log

    return check_stub('mlink')[1] unless check_stub('mlink')[0]
    toggle_pager(h, "unpaged")
    stub, out, expects = STUBS['mlink'], clean(h.send("mlink #{args[0]}")), {}
    expects['link matches'] = ( clean(stub.lines[2]) == clean(out.lines[2]) )

    # Run logrotate to test it and to prevent links.log overrun
    ssh.send("perl #{args[1]}")
    log_ln = ssh.send("wc -l #{args[2]}").split.first.to_i
    expects['reset links.log (3 lines)'] = ( log_ln == 3 ? true : log_ln )

    # Verify HTTPS
    out_ssl = clean(out.lines[4]).match(/URL is: (.*?)\/\//)[1].to_s.chop
    expects['using https'] = ('https' == out_ssl.to_s)

    # Verify link ID consistency
    out_id = clean(out.lines[4]).match(/^(.*?)(\w\d+\.)$/)[2].to_s.chop
    log_id = clean(h.send('vlog links')).match(/\=\>(.*?)$/)[1].strip.to_s
    expects['ID in links.log matches'] = ( out_id == log_id ? true : log_id )

    passfail = expects.values.all? { |x| x == true }
    return [:results, passfail, "all true", output_hash(expects)]
  end

  def file_manifest(h, ssh)
    return check_stub('file_manifest')[1] unless check_stub('file_manifest')[0]
    manifest = STUBS['file_manifest']
    expected = manifest.map{ |f| [f, true] }.to_h
    success, err, i, cmd_list, actual = 0, 0, 0, {}, {}

    # Cleanup old temp files
    ssh.send("rm #{TEMP}")

    # Batch manifest into chunks for faster performance over SSH
    manifest.each_slice(10) do |files|
      slice = files.join(' ')
      cmd_list[[slice]] = "for i in #{slice} ; do [ -e $i ] && "\
        "echo \"$i: true\" || echo \"$i: false\" ; done >> #{TEMP}"
    end

    # Send, read results, remove temp file
    execute_commands = ssh.send(cmd_list)
    results = ssh.send("cat #{TEMP}")
    ssh.send("rm #{TEMP}")
    results = Hash[results.split(/\n/).map { |x| x.split ": " }]

    # Check results
    manifest.each do |file|
      check = results[file]
      check = true if check == "true"
      check = false if check == "false"
      actual[file] = check
    end
    diff = actual.reject { |k, v| v == true }
    return [
      :results, expected == actual,
      "`true` for #{manifest.count} files", output_hash(diff)
    ]
  end

  def website_on_now(h, ssh, args)
    # Expected args are locations of:
    # [0]: people.count
    # [1] onnow.cgi
    # [2] index.cgi
    expects = {}

    # Actual number of people on the talker
    expects['t_onnow'] = NumbersInWords.in_numbers(clean(h.send('where').
      lines[0]).match(/There are (.*?) people/)[1].strip.to_s).to_s

    # talker -> people.count
    expects['people.count'] = clean(ssh.send("cat #{args[0]}")).to_s

    # people.count -> onnow.cgi
    expects['onnow.cgi'] = clean(ssh.send("perl #{args[1]}").lines[-1]).to_s

    # people.count -> index.cgi
    expects['index.cgi'] = ssh.send("perl #{args[2]}").
      match(/<b>(\d+)<\/b> people/)[1].to_s

    passfail = expects.values.all? { |x| x == expects['t_onnow'] }
    return [:results, passfail, "all match", output_hash(expects)]
  end
end
