class Report
  # Format and print test results and other messages
  attr_accessor :score

  def initialize(type: , cmd: nil, test_name: , test_results: [], message: '')
    @type, @cmd, @test_name = type, cmd.dup, test_name.dup
    @test_results, @message = test_results.dup, message
    @score = { fail: 0, pass: 0, err: 0 }
    puts self.parse
    return @score
  end

  def parse
    stack = ''
    @cmd = "#{@cmd.bold}: " unless @cmd.nil?
    # Properly-formatted test results
    if @type == :results && @test_results[0] == :results
      test_passed = @test_results[1]
      if test_passed then
        stack << "#{@cmd}#{@test_name}".pass
        @score[:pass] +=1
      else
        stack << "#{@cmd}#{@test_name}".failure
        unless @test_results[2].nil?
          stack << "\n#{"Expected".bold}: #{@test_results[2]}".wrap(7).red
          stack << "\n#{"Received".bold}: #{@test_results[3]}".wrap(7).red
        end
        @score[:fail] +=1
      end
    # Improperly-formatted test results
    elsif @type == :results
      stack << "#{FAILURE} Unexpected response from: "\
        "#{@cmd}#{@test_name}".magenta
        stack << "\n#{PAD} Response: #{@test_results.inspect}".magenta
        @score[:err] +=1
    # Error report
    elsif @type == :error
      stack << "Error running #{@test_name}: ".failure
      stack << "#{@message}".red
      @score[:err] +=1
    # Something else
    else
      stack << "#{EMPTY} How did we get here?".magenta
      stack << "\n#{PAD} test_name:    #{@test_name}".magenta
      stack << "\n#{PAD} test_results: #{@test_results.inspect}".magenta
      stack << "\n#{PAD} message:\n".magenta
      stack << @message.magenta.wrap(7)
    end
  return stack
  end
end
