PASS     = "\n    \u2705"
FAILURE  = "\n    \u274c"
EMPTY    = "\n    \u2753"
LOGIN    = "\n    \u25B6"
LOGOUT   = "\n    \u25C0"
WAITING  = "\n    \u2615"
PAD      = "      "

class String
  def red;      "\e[31m#{self}\e[0m" end
  def green;    "\e[32m#{self}\e[0m" end
  def blue;     "\e[34m#{self}\e[0m" end
  def magenta;  "\e[35m#{self}\e[0m" end
  def cyan;     "\e[36m#{self}\e[0m" end
  def bold;     "\e[1m#{self}\e[22m" end
  def failure;  self.prepend("#{FAILURE} "); return self.red end
  def pass;     self.prepend("#{PASS} "); return self.green end
  def waiting;  self.prepend("#{WAITING} "); end
  def login;    self.prepend("#{LOGIN} ".green); end
  def logout;   self.prepend("#{LOGOUT} ".green); end

  def wrap(padding = 4)
    pad = ' ' * padding
    self.prepend(pad)
    chars, stack, i = self.split(""), [], 0
    chars.each do |c|
      twidth = 76 - padding
      (c = "\n#{pad}"; i = 0) if (c == "\n") || (i >= twidth && c == " ")
      stack << c; i += 1
    end
    return stack.join("").to_s
  end
end