class NRZI < Array
  def decode
    one_count = 0
    self.map do |c|
      if c == 0
        one_count += 1
        1
      else
        next one_count = 0 if one_count >= 6
        one_count = 0
        0
      end
    end.compact
  end
end
