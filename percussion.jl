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
using Interpolations
using SampledSignals
using PortAudio

#-------------experiments---------------------
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
#-------------experiments---------------------
function bassDrum()
  return bass_drum
end

#create an exponential function 
function expon(start_val, end_val, dur, t)
  return start_val * ((end_val / start_val) ^ (t / dur))
end

function expon_func(start_val, end_val, dur, sample_rate)
  return expon.(start_val, end_val, dur, 0:1/sample_rate:dur)
end

#create an oscillator 
function oscil(amp, freq, table_interp, t, sample_rate)
    # Calculate the index for the table lookup with wrapping for periodicity
    index = mod1(t * freq, length(table_interp))
    return amp * table_interp(t * freq * sample_rate)
    
end

function oscil_func(amp, table_interp, duration, sample_rate)
  # Calculate the index for the table lookup with wrapping for periodicity
  a1 = zeros(Float64, floor(Int, duration * sample_rate))
  for t in 1:length(a1)
    time = t / sample_rate
    k1 = expon(120, 50, 0.2, time)
    k2 = expon(500, 200, 0.4, time)
    a1[t] = oscil(amp, k1, table_interp, time, sample_rate)
    # Process `a1` such as writing to an output buffer
    # ...
  end
  return a1
end


duration = 1    # duration of the signal in seconds
sample_rate = 44100 # common sample rate for audio in Hz
t = 0:1/sample_rate:duration

sine_wave_table = sin.(2 * π * (t))  # A simple sine wave table from 0 to 1
sine_wave_interp = LinearInterpolation(1:length(sine_wave_table), sine_wave_table, extrapolation_bc=Periodic())

function interpolate(table_interp, index)
    # `index` can be a non-integer, and the interpolation scheme will handle it
    return table_interp(index)
end

iamp = 100000

k1 = expon_func(120, 50, 0.2, sample_rate)
k2 = expon_func(500, 200, 0.4, sample_rate)
bass_drum = oscil_func(iamp, sine_wave_interp, 0.25, sample_rate)
#BASS DRUM SIGNAL


kcutfreq = expon.(10000, 2500, .1, t)
t = 0:1/sample_rate:duration
amp = expon.(10000, 20, 0.1, t)

seed!(0)
hihat = []
for i in 1:(4410)
  global hihat = [hihat; ((rand()*2 - 1) * amp[i])]
end
#HIHAT SIGNAL

function envelope(x; w::Int = 201) # uses moving average
  h = (w-1) ÷ 2 # sliding window half-width (default 100)
  x = abs.(x) # absolute value is crucial!
  avg(v) = sum(v) / length(v) # function for (moving) average
  return [avg(x[max(n-h,1):min(n+h,end)]) for n in 1:length(x)]
end

#filter the signals TODO
responsetype = Lowpass(5; fs=50)
designmethod = Butterworth(2)
filt(digitalfilter(responsetype, designmethod), amp)

# for i in 1:4
#   global arand = [arand; arand];
# end
# soundsc(arand, sample_rate)
t = 0:1/sample_rate:0.25
t = t[1:floor(Int, 0.25*sample_rate)]
env = (1 .- exp.(-80*t)) .* exp.(-30*t)
bass_drum = env .* bass_drum


ans = zeros(floor(Int, 0.25 * sample_rate))
ans[1:4410] = hihat

fullHihat = ans
#ans .+= bass_drum

result = [zeros(floor(Int, 2 * sample_rate))]

buf = SampleBuf(ans, sample_rate)
soundsc(ans, sample_rate)

loop = zeros(2 * sample_rate)
eigthNote = 11025
for i in 1:8
  loop[(i-1)*eigthNote+1:i*eigthNote] .+= fullHihat
end
for i in 1:2:8
  loop[(i-1)*eigthNote+1:i*eigthNote] .+= bass_drum
end
soundsc(loop, sample_rate)

wavwrite(loop, "touch.wav", Fs=sample_rate)

x, S = wavread("touch.wav")
plot(x)

