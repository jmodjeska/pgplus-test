require_relative './strings.rb'
require 'time'

module Helpers
  def timeline(position, starttime, scores=nil)
    if position == :start
      return "#{'-' * 43} [ #{starttime} ]\n".bold.cyan
    elsif position == :end
      diff = Time.parse(Time.new.inspect)-Time.parse(starttime)
      diff = sprintf("%09.4f", diff)
      sk = scores.map { |k, v| sprintf("%04s %s", v.to_s, k.to_s ) }.join('')
      stack = "#{'-' * 14} [".cyan
      stack << sk.blue
      stack << "   ] - [ completed in #{diff} secs ]\n".cyan
      return stack
    end
  end

  def output_hash(h)
    return h.map { |k, v| "#{k} => #{v}" }.join("\n")
  end
end
