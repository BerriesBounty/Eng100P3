#produced synthsizer sound with additive synthesis

using Gtk
using Sound: sound
using Sound: soundsc
using WAV
using MAT: matwrite
using FFTW: fft
using Plots;
using DSP: Windows

freql = [523.25, 554.37, 587.33, 622.25, 659.26, 698.46, 739.99, 783.99, 830.61, 880, 932.33, 987.77]

S = 44100
N = 32768
totalLength = N * 12
t = (0:N-1)/S # time samples: t = n/S
I = 0 .+ 1.2*t/maximum(t) # slowly increase modulation index
instrument = zeros(totalLength)

for i in 1:12
  x = sin.(2π*freql[i]*t + I .* sin.(2π*300*t))
  instrument[(i-1)*N+1:i*N] += x;
end
soundsc(instrument, S)
