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





# snare code

# Define the exponential decay function
function expon(start_val, end_val, dur, t)
  return start_val * ((end_val / start_val) ^ (t / dur))
end

# Create a function for generating noise with an exponential amplitude envelope
function generate_noise_with_envelope(start_amp, end_amp, duration, sample_rate)
  t = 0:1/sample_rate:duration
  envelope = expon.(start_amp, end_amp, duration, t)
  noise = randn(length(t))
  return noise .* envelope
end

# Create a function for generating a snare drum sound
function snareDrum(sample_rate=44100, duration=0.25)
  # Noise component
  noise_amp_start = 1.0
  noise_amp_end = 0.01
  noise_component = generate_noise_with_envelope(noise_amp_start, noise_amp_end, duration, sample_rate)
  
  # Tonal component
  tone_freq = 250 # Frequency in Hz for the tonal component
  t = 0:1/sample_rate:duration
  tone = sin.(2 * π * tone_freq * t)
  tone_envelope = expon.(1.0, 0.01, duration, t)
  tone_component = tone .* tone_envelope

  # Combine tone and noise
  snare_sound = noise_component + tone_component

  return snare_sound
end

# Example usage
sample_rate = 44100
duration = 0.25 # Snare sound duration in seconds
snare_sound = snareDrum(sample_rate, duration)

# Play the snare sound
soundsc(snare_sound, sample_rate)

# Optionally save to a WAV file
wavwrite(snare_sound, "snare.wav", Fs=sample_rate)

# Plotting the waveform
plot(snare_sound, title="Snare Drum Waveform", xlabel="Sample", ylabel="Amplitude")




using DSP, WAV

# Function to generate a tom drum sound
function generate_tom_drum(sample_rate, duration, start_freq, end_freq)
    # Time vector
    t = collect(0:1/sample_rate:(duration - 1/sample_rate))
    
    # Exponential decay in frequency to simulate pitch drop
    freq_decay = exp.(log.(end_freq / start_freq) .* t / duration) .* start_freq
    
    # Amplitude envelope to simulate the strike decay
    amp_decay = exp.(-12 * t)  # Increased decay rate for shorter sound
    
    # Generate the tone with varying frequency
    signal = sin.(2 * π * freq_decay .* t) .* amp_decay
    
    # Optionally, apply a low-pass filter to smooth the sound, simulating the drum membrane's characteristics
    lpf = digitalfilter(Lowpass(2500; fs=sample_rate), Butterworth(2))
    filtered_signal = filt(lpf, signal)
    
    return filtered_signal
end

# Parameters for the tom drum sound
sample_rate = 44100  # Sample rate in Hz
duration = 0.25      # Duration of the sound in seconds, as requested
start_freq = 200     # Starting frequency in Hz
end_freq = 100       # Ending frequency in Hz, to simulate the pitch drop

# Generate the tom drum sound
tom_drum_sound = generate_tom_drum(sample_rate, duration, start_freq, end_freq)

# Normalize the tom drum sound to prevent clipping
tom_drum_sound /= maximum(abs.(tom_drum_sound))

# Save the tom drum sound to a WAV file
wavwrite(tom_drum_sound, "tom_drum_short.wav", Fs=sample_rate)

# If you want to play the sound directly (ensure your environment supports it)
# soundsc(tom_drum_sound, sample_rate)






# Function to generate a crash cymbal sound
function generate_crash_cymbal(sample_rate, duration)
  # Correctly generate white noise with an integer size
  noise = randn(Float64, round(Int, sample_rate * duration))
  
  # Create an amplitude envelope for the crash cymbal sound
  t = collect(0:1/sample_rate:(duration - 1/sample_rate))
  envelope = exp.(-5 * t)  # Modify the decay rate as needed
  
  # Apply the envelope to the white noise
  crash_sound = noise .* envelope
  
  # Apply a bandpass filter to emphasize the metallic tone of the cymbal
  bpf = digitalfilter(Bandpass(2000, 8000; fs=sample_rate), Butterworth(4))
  filtered_crash_sound = filt(bpf, crash_sound)
  
  return filtered_crash_sound
end

# Parameters for the crash cymbal sound
sample_rate = 44100  # Sample rate in Hz
duration = 2.0       # Duration of the sound in seconds

# Generate the crash cymbal sound
crash_cymbal_sound = generate_crash_cymbal(sample_rate, duration)

# Normalize the crash cymbal sound to prevent clipping
crash_cymbal_sound /= maximum(abs.(crash_cymbal_sound))

# Save the crash cymbal sound to a WAV file
wavwrite(crash_cymbal_sound, "crash_cymbal.wav", Fs=sample_rate)

# If you want to play the sound directly (ensure your environment supports it)
# soundsc(crash_cymbal_sound, sample_rate)






# Function to generate a ride cymbal sound
function generate_ride_cymbal(sample_rate, duration)
  # Generate white noise
  noise = randn(Float64, round(Int, sample_rate * duration))
  
  # Create a series of band-pass filters to simulate the metallic tones of the ride cymbal
  filters = [
      digitalfilter(Bandpass(400, 600; fs=sample_rate), Butterworth(2)),
      digitalfilter(Bandpass(800, 1200; fs=sample_rate), Butterworth(2)),
      digitalfilter(Bandpass(2500, 3500; fs=sample_rate), Butterworth(2))
  ]
  
  # Apply filters to the noise
  filtered_noise = sum([filt(f, noise) for f in filters], dims=1)
  
  # Create an amplitude envelope for the ride cymbal sound
  # This envelope simulates a slight attack and a longer sustain
  t = collect(0:1/sample_rate:(duration - 1/sample_rate))
  envelope = exp.(-1 * t)  # A slower decay compared to crash cymbal
  
  # Apply the envelope to the filtered noise
  ride_sound = filtered_noise .* envelope'
  
  return ride_sound
end

# Parameters for the ride cymbal sound
sample_rate = 44100  # Sample rate in Hz
duration = 2.0       # Duration of the sound in seconds

# Generate the ride cymbal sound
ride_cymbal_sound = generate_ride_cymbal(sample_rate, duration)

# Normalize the ride cymbal sound to prevent clipping
ride_cymbal_sound /= maximum(abs.(ride_cymbal_sound))

# Save the ride cymbal sound to a WAV file
wavwrite(ride_cymbal_sound, "ride_cymbal.wav", Fs=sample_rate)

# If you want to play the sound directly (ensure your environment supports it)
# soundsc(ride_cymbal_sound, sample_rate)