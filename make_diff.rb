file_name = file_name = ARGV[0]
float_bin = File.binread("./#{file_name}.float")
float = float_bin.unpack('f*')

diff = float[500000...-1].each_cons(2).map do |previous, following|
  (following - previous) / 0.00001
end

diff_bin = diff.pack('f*')

File.open("./#{file_name}-diff.float", 'wb') do |f|
  f.write diff_bin
end

threshold = diff[0..50000000].max(100).inject(0.0) { |r, i| r += i } / 100

puts "#{threshold}: #{threshold}"
