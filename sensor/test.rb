require "open3"
include Math

system("timeout 5s arecord  -D plughw:0,0 -f cd /tmp/test.wav")
o,e = Open3.capture2e("sox -t .wav /tmp/test.wav -n stat")
v = o.match("Maximum amplitude:[ ]*[0-9].[0-9]*\n").to_s.match("[0-9].[0-9]*").to_s.to_f
puts 20 * ( Math.log10( (2*10**-5)/ v )).abs
