require './differential'
require './nrzi'

file_name = ARGV[0]
threshold = ARGV[1] / 2

diff = File.binread("./#{file_name}-diff.float")

data = Differential.new(diff, threshold: threshold, samp_per_bit: 6.7)

start = 0
sign = 1

coefficient = nil

File.open("./#{file_name}.decoded", 'w') do |decoded|
  pressing_prev = []
  pressing = []

  10000000.times do
    preamble_flag = 0
    while preamble_flag < threshold
      start += 1
      preamble_flag = data[start]
      if preamble_flag.nil?
        break
      end
    end

    if preamble_flag.nil?
      break
    end

    sign = 1
    changes = [sign]
    changes += data.decode(start: start, division: 7, sign: sign)
    nrzi = NRZI.new(changes)
    next if nrzi.decode.join != '00000001'

    preamble_start = start

    changes = [sign]

    100.times do |i|
      coefficient, next_start_point, next_count = data.find_next_seven(start)
      break if coefficient.nil?

      division = next_count
      changes += data.decode(start: start, division: division, sign: sign)
      start = next_start_point
      sign = coefficient
    end

    nrzi = NRZI.new(changes)

    bits = nrzi.decode.join
    key_status = {}
    preamble_index = 0
    bits = bits[preamble_index..-1] if preamble_index = bits.index(/0000000111000011/)
    pressing = []
    if bits =~ /\A\d{8}11000011/ && bits =~ /\A\d{16}0{16}/
      bits[32..-1].scan(/.{1,8}/)[0..5].each do |byte|
        key_code = byte.reverse.to_i(2)
        if key_code >= 0x04 && key_code <= 0x1d
          key = (key_code + 93).chr
        end
        key = ' ' if key_code == 0x2c
        key = ',' if key_code == 0x36
        key = '.' if key_code == 0x37
        pressing << key unless key.nil? || pressing_prev.include?(key)
      end
      (pressing_prev - pressing).each do |key|
        print key
      end
      pressing_prev = pressing
    end
    decoded.puts nrzi.decode.join
  end
  pressing_prev.each do |key|
    print key
  end
end

puts ''
