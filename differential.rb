class Differential < Array
  def initialize(binary, threshold: 2000, samp_per_bit: 3.4, sign: 1)
    @threshold = threshold
    @samp_per_bit = samp_per_bit
    @sign = sign
    super binary.unpack('f*')
  end

  def find_maximum_point(point:, range: @samp_per_bit, sign: 0)
    half_samp_per_bit = (range / 2.0).floor
    if sign == 0
      left = [1] + self[(point - half_samp_per_bit)..point].map { |d| d.abs > @threshold ? d : 0 }
      right = self[point..(point + half_samp_per_bit)].map { |d| d.abs > @threshold ? d : 0 } + [1]
      left_index = left.index(left.max_by { |d| d.abs })
      right_index = right.index(right.max_by { |d| d.abs })
      if (left.length - left_index - 1) < right_index
        max = left[left_index]
        max_point = point - (left.length - left_index - 1)
      else
        max = right[right_index]
        max_point = point + right_index
      end
    else
      chunk = self[(point - half_samp_per_bit)..(point + half_samp_per_bit)]
      if sign.positive?
        max = chunk.max
        max_point = point + chunk.index(max) - half_samp_per_bit
      else
        max = chunk.min
        max_point = point + chunk.index(max) - half_samp_per_bit
      end
    end
    [coefficient_of(max), max_point]
  end

  def compare(left, right, which)
    if which == :max
      [[self[left], left], [self[right], right]].max_by { |item| item[0] }
    else
      [[self[left], left], [self[right], right]].min_by { |item| item[0] }
    end
  end

  def update(current, max, current_point, max_point, sign)
    if (current * sign) > (max * sign)
      [current, current_point]
    else
      [max, max_point]
    end
  end

  def find_next_seven(point)
    7.downto(1) do |i|
      estimated = (@samp_per_bit * i).round
      coefficient, max_point = find_maximum_point(point: point + estimated)

      return coefficient, max_point, i if coefficient.abs > 0
    end

    nil
  end

  def decode(start: , division: 7, sign:)
    if sign
      sign *= -1
    else
      sign = 0
    end

    1.upto(division).map do |i|
      point = start + (@samp_per_bit * i).round
      coefficient, max_point = find_maximum_point(point: point, sign: sign)
      sign *= -1 if coefficient != 0
      coefficient
    end
  end

  def coefficient_of(value)
    if value.abs < @threshold
      0
    else
      if value.positive?
        1
      else
        -1
      end
    end
  end
end
