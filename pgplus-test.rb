Dir[File.join(__dir__, 'lib', '*.rb')].each { |file| require file }
require 'optimist'
include Helpers
include Tests

##################################################
# CONSTANTS

PLAN = YAML.load_file('config/test-plan.yaml')
default_profile = 'test'

##################################################
# CLI ARGUMENTS

o = Optimist::options do
  banner "\nSynopsis: ruby pgplus-test.rb [ -dh ]\n\n"
  opt :dev_mode, "Only run tests specified in `development` section"
  opt :basic, "Only run test in the `basic_commands` section"
  opt :profile, "Specify a test profile for non-admin tests)",
    :default => default_profile
end

dev_mode = o[:dev_mode]
basic_mode = o[:basic]
profile = o[:profile]

unless CONFIG.dig('profiles', profile)
  abort "Profile `#{profile.bold}` does not exist."
end

##################################################
# TEST EXECUTION FUNCTIONS

def report_nonexistent_test(e, test_name=nil)
  method_name = test_name.bold + ": " + e.to_s[/`(.*?)'/,0]
  message = "\nThis test doesn't exist, a method within the test "\
    "failed. Make sure the test returns results, and check for red "\
    "error messages in #{LOG}.".wrap(7)
  File.write(LOG, "\n\n-=> PG+ TEST ERROR <=-\n\n#{e}\n\n".red, mode: 'a+')
  r = Report.new(type: :error, test_name: method_name, message: message)
  @sk.add(r.score)
end

def send_and_report_tests(test_name, test_args, cmd = nil)
  begin
    File.write(LOG, "\n\n-=> PG+ TEST START <=-\n\n"\
      "#{test_name}\n\n".cyan, mode: 'a+')
    test_results = __send__(test_name, *test_args)
    r = Report.new(type: :results, test_name: test_name, cmd: cmd,
      test_results: test_results)
    @sk.add(r.score)
  rescue NoMethodError => e
    report_nonexistent_test(e, test_name)
  else
    return test_results
  end
end

def run_basic_tests(h, cmd, test_hash)
  cmd_output = h.send(cmd)
  test_hash.each do |test_name, args|
    test_args = [cmd, cmd_output]
    test_args << args unless args.nil?
    send_and_report_tests(test_name, test_args, cmd)
  end
end

def run_custom_tests(h, section_name)
  if PLAN[section_name].nil? then h.done else
    PLAN[section_name].each do |test_definition|
      test_name = test_definition.first[0]
      test_args = [h]
      test_args << ConnectSSH.new if test_definition.dig(test_name, 'ssh')
      args = test_definition.dig(test_name, 'args') || false
      test_args << args if args
      send_and_report_tests(test_name, test_args)
    end
    h.done
  end
end

##################################################
# RUNTIME

starttime = Time.new.inspect
puts timeline(:start, starttime)
@sk = Scorekeeper.new

begin
  # Section: Basic Command Tests
  unless dev_mode
    h = ConnectTelnet.new('basic commands', profile)
    PLAN['basic_commands'].each do |test_definition|
      test_name = test_definition.first[0]
      cmd = test_definition.dig(test_name, 'cmd')
      tests_to_run = test_definition.dig(test_name, 'tests_to_run')
      run_basic_tests(h, cmd, tests_to_run)
    end
    h.done
  end

  # Section: Other Tests (non-admin)
  unless dev_mode || basic_mode
    h = ConnectTelnet.new('other tests', profile)
    run_custom_tests(h, 'other_tests')
  end

  # Section: Admin Tests
  unless dev_mode || basic_mode
    h = ConnectTelnet.new('admin tests', 'test_admin')
    run_custom_tests(h, 'admin_tests')
  end

  # Section: Development
  # (only run tests in the `development` section)
  if dev_mode then
    h = ConnectTelnet.new('development mode', 'test_admin')
    run_custom_tests(h, 'development')
  elsif !basic_mode
    puts "-=> Skipping development tests (use `-d` to enable)\n\n"
  end

rescue Net::ReadTimeout => e
  puts "\n-=> Timed out waiting for talker response.".bold.red
  puts "HINT: You might end up here if the test character wasn't properly "\
      "logged out (try again) or if the `prompt` config doesn't exactly "\
       "match the test user's talker prompt, including properly escaped "\
       "characters for regex compatibility. See "\
       "https://github.com/jmodjeska/pgplus-test for examples.\n".wrap
end

puts timeline(:end, starttime, @sk.report)