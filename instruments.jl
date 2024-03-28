using Gtk
using Sound: sound
using Sound: soundsc
using WAV
using MAT: matwrite
using FFTW: fft
using Plots;

(x, S) = wavread("project3.wav"); #soundsc(x, S)
N = length(x)
noteLength = round(Int, N/(13*4))
numNotes = 13*4
instruments = zeros(round(Int,N/4)) * ones(4)'
@show size(instruments)
for j in 1:4
  for i in 1:13
    instruments[(i-1)*noteLength+1:i*noteLength, j] = x[(i-1)*noteLength+1 + (j-1)*13*noteLength: i*noteLength + (j-1)*13*noteLength]
  end
end

N = 11025
realInstruments = zeros(N*13) * ones(4)'
for j in 1:4
  for i in 1:13
    realInstruments[(i-1)*N+1:i*N, j] = instruments[(i-1)*noteLength+1: (i-1)*noteLength+N, j]
  end
end

function getNote(idx, j)
  return realInstruments[(idx-1)*N+1:idx*N, j]
end


