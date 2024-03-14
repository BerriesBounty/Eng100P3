using Gtk
using Sound: sound
using Sound: soundsc
using WAV
using MAT: matwrite
using FFTW: fft
using Plots;
using DSP
using Distributions
using Random: seed!

# function exp_freq(t, f_start, f_end, duration)
#   k = log(f_end / f_start) / duration
#   return f_start * exp(k * t)
# end

# # Create a sampled signal
# function create_exponential_tone(f_start, f_end, duration, sample_rate)
#   t = 0:1/sample_rate:duration
#   signal = [cos(2 * π * exp_freq(ti, f_start, f_end, duration) * ti) for ti in t]
#   return signal
# end

# # Parameters for the signal
# f_start = 10000      # start frequency in Hz
# f_end = 2500        # end frequency in Hz
# duration = 0.1     # duration of the signal in seconds
# sample_rate = 44100 # common sample rate for audio in Hz

# # Generate the signal
# kcutfreq = create_exponential_tone(f_start, f_end, duration, sample_rate)
# sound(kcutfreq, sample_rate)

# amp = create_exponential_tone(10000, 10, 0.1, sample_rate)
# sound(amp, sample_rate)

function exponential_growth(f_start, f_end, duration, sample_rate)
  t = 0:1/sample_rate:duration
  A = f_start # starting value
  growth_factor = log(f_end/f_start) / duration # calculated rate of growth
  return A * exp.((t * growth_factor))
end


# Parameters for the signal
f_start = 10000      # start frequency in Hz
f_end = 2500        # end frequency in Hz
duration = 0.1     # duration of the signal in seconds
sample_rate = 44100 # common sample rate for audio in Hz

kcutfreq = exponential_growth(10000, 2500, .1, sample_rate)
amp = exponential_growth(10000, 10, .1, sample_rate)

seed!(0)
arand = []
for i in 1:(4410)
  global arand = [arand; ((rand()*2 - 1) * amp[i])]
end

# responsetype = Lowpass(5; fs=50)
# designmethod = Butterworth(2)
# filt(digitalfilter(responsetype, designmethod), amp)

for i in 1:4
  global arand = [arand; arand];
end
soundsc(arand, sample_rate)

using PortAudio: PortAudioStream, write

stream = PortAudioStream(0, 1; warn_xruns=false)

function play_tone(stream, freq::Real, duration::Real; buf_size::Int = 1024)
    S = stream.sample_rate
    current = 1
    while current < duration*S
        x = 0.7 * sin.(2π * (current .+ (1:buf_size)) * freq / S)
        if(current > duration*S*0.5)
          x = arand
        end
        write(stream, x)
        current += buf_size
    end
    nothing
end

play_tone(stream, 440, 2)

