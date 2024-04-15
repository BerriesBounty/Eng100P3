using PortAudio: PortAudioStream, write
using Gtk
using Plots;
using Sound: soundsc
include("instruments.jl")

t = (1:44100) ./ 44100
env = 1 .- exp.(50*(t.-1))
plot(env[1:44100])
print(t)


