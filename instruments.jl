using Gtk
using Sound: sound
using Sound: soundsc
using WAV
using MAT: matwrite
using FFTW: fft
using Plots;
using DSP: Windows

(x, S) = wavread("project3.wav"); #soundsc(x, S)

M = round(Int, S/3)
window = Windows.kaiser(M+1, 1)[1:M] # Hanning window

N = length(x)
noteLength = round(Int, N/(13*4))
numNotes = 13*4
instruments = zeros(round(Int,N/4)) * ones(4)'
for j in 1:4
  for i in 1:13
    instruments[(i-1)*noteLength+1:i*noteLength, j] = x[(i-1)*noteLength+1 + (j-1)*13*noteLength: i*noteLength + (j-1)*13*noteLength]
  end
end

attack = 0.05


function getAttack(idx, j)
  return instruments[(idx-1)*noteLength+1:(idx-1)*noteLength+round(Int, attack*S), j]
end

function getNote(idx, j)
  signal = instruments[(idx-1)*noteLength+1:idx*noteLength, j]
  duration = Int(2 * S)
  Nseg = round(Int, duration/M)
  print(Nseg)
  sustain = signal[(1:M) .+ round(Int, attack*S)]
  sustain = sustain .* window
  z = zeros(round(Int, duration))
  for seg in 1:(2*Nseg-1)
    index = (1:M) .+ (seg-1)*(M÷2)
    z[index] .+= sustain
  end
  return z
end

note = getNote(4,1)
soundsc(note, S)
plot(note)
