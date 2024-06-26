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

#create an exponential function 
# function expon(start_val, end_val, dur, t)
#   return start_val * ((end_val / start_val) ^ (t / dur))
# end

# function expon_func(start_val, end_val, dur, sample_rate)
#   return expon.(start_val, end_val, dur, 0:1/sample_rate:dur)
# end

# #create an oscillator 
# function oscil(amp, freq, table_interp, t, sample_rate)
#     # Calculate the index for the table lookup with wrapping for periodicity
#     index = mod1(t * freq, length(table_interp))
#     return amp * table_interp(t * freq * sample_rate)
    
# end

# function oscil_func(amp, table_interp, duration, sample_rate)
#   # Calculate the index for the table lookup with wrapping for periodicity
#   a1 = zeros(Float64, floor(Int, duration * sample_rate))
#   for t in 1:length(a1)
#     time = t / sample_rate
#     k1 = expon(120, 50, 0.2, time)
#     k2 = expon(500, 200, 0.4, time)
#     a1[t] = oscil(amp, k1, table_interp, time, sample_rate)
#     # Process `a1` such as writing to an output buffer
#     # ...
#   end
#   return a1
# end


# duration = 1    # duration of the signal in seconds
# sample_rate = 44100 # common sample rate for audio in Hz
# t = 0:1/sample_rate:duration

# sine_wave_table = sin.(2 * π * (t))  # A simple sine wave table from 0 to 1
# sine_wave_interp = LinearInterpolation(1:length(sine_wave_table), sine_wave_table, extrapolation_bc=Periodic())

# function interpolate(table_interp, index)
#     # `index` can be a non-integer, and the interpolation scheme will handle it
#     return table_interp(index)
# end

# iamp = 100000

# k1 = expon_func(120, 50, 0.2, sample_rate)
# k2 = expon_func(500, 200, 0.4, sample_rate)
# bass_drum = oscil_func(iamp, sine_wave_interp, 0.25, sample_rate)

# t = 0:1/sample_rate:0.25
# t = t[1:floor(Int, 0.25*sample_rate)]
# env = (1 .- exp.(-80*t)) .* exp.(-30*t)
# bass_drum = env .* bass_drum
# bass_drum /= maximum(abs.(bass_drum))
# wavwrite(bass_drum, "bass_drum.wav", Fs=sample_rate)

# kcutfreq = expon.(10000, 2500, .1, t)
# t = 0:1/sample_rate:duration
# amp = expon.(10000, 20, 0.1, t)
 
# seed!(0)
# hihat_short = []
#  for i in 1:(4410)
#   global hihat_short = [hihat_short; ((rand()*2 - 1) * amp[i])]
# end
# max_amp = maximum(abs.(hihat_short))
# hihat_short = hihat_short / max_amp
# hihat = zeros(floor(Int, 0.25 * sample_rate))
# hihat[1:4410] = hihat_short
# wavwrite(hihat, "hihat.wav", Fs=sample_rate)

#------------------------------------------------------------------------------------------
sample_rate = 44100

function bass_drum_func(sample_rate, duration, start_freq, end_freq, amplification_factor)
  t = 0:1/sample_rate:duration

  freq_decay = exp.(log.(end_freq / start_freq) .* t / duration) .* start_freq

  amp_decay = exp.(-10 * t)
  # changed -15 to -10

  signal = sin.(2 * π * freq_decay .* t) .* amp_decay

  amplified_signal = signal * amplification_factor 

  lpf = digitalfilter(Lowpass(100; fs=sample_rate), Butterworth(2))
  filtered_signal = filt(lpf, amplified_signal)

  soft_clipped_signal = tanh.(filtered_signal)
  max_amp = maximum(abs.(soft_clipped_signal))
  normalized_signal = soft_clipped_signal / max_amp

  return normalized_signal
end

duration = 0.25
start_freq = 150
end_freq = 60
bass_drum_sound = bass_drum_func(sample_rate, 0.25, start_freq, end_freq, 6)
wavwrite(bass_drum_sound, "bass_drum_normalized.wav", Fs=sample_rate)
#BASS DRUM SIGNAL



function hi_hat_func(sample_rate, duration)
  t = 0:1/sample_rate:duration

  noise = randn(Float64, length(t))
  env = exp.(-50 * t)
  
  hi_hat_sound = noise .* env

  hpf = digitalfilter(Highpass(10000; fs=sample_rate), Butterworth(4))
  filtered_hi_hat_sound = filt(hpf, hi_hat_sound)

  filtered_hi_hat_sound /= maximum(abs.(filtered_hi_hat_sound))
  
  return filtered_hi_hat_sound
end

hi_hat_sound = hi_hat_func(sample_rate, duration)
wavwrite(hi_hat_sound, "hi_hat.wav", Fs=sample_rate)

# snare code
function expon(start_val, end_val, dur, t)
  return start_val * ((end_val / start_val) ^ (t / dur))
end

function generate_noise_with_envelope(start_amp, end_amp, duration, sample_rate)
  t = 0:1/sample_rate:duration
  envelope = expon.(start_amp, end_amp, duration, t)
  noise = randn(length(t))
  return noise .* envelope
end

# Create a function for generating a snare drum sound
function snareDrum(sample_rate=44100, duration=0.25)
  # Noise
  t = 0:1/sample_rate:duration
  envelope = expon.(1.0, 0.01, duration, t)
  noise = randn(length(t))
  noise_component = noise .* envelope
  
  # Tone
  tone_freq = 250
  tone = sin.(2 * π * tone_freq * t)
  tone_envelope = expon.(1.0, 0.01, duration, t)

  tone = tone .* tone_envelope

  snare_sound = noise_component + tone

  return snare_sound
end

snare_sound = snareDrum(sample_rate, duration)

# Play the snare sound
soundsc(snare_sound, sample_rate)

# Optionally save to a WAV file
wavwrite(snare_sound, "snare.wav", Fs=sample_rate)

# Plotting the waveform
plot(snare_sound, title="Snare Drum Waveform", xlabel="Sample", ylabel="Amplitude")


# Function to generate a tom drum sound
function generate_tom_drum(sample_rate, duration, start_freq, end_freq)
    # Time vector
    t = 0:1/sample_rate:duration
    
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
  t = 1/sample_rate:1/sample_rate:duration
  envelope = exp.(-5 * t)  # Modify the decay rate as needed
  
  # Apply the envelope to the white noise
  crash_sound = noise .* envelope
  
  # Apply a bandpass filter to emphasize the metallic tone of the cymbal
  bpf = digitalfilter(Bandpass(2000, 8000; fs=sample_rate), Butterworth(4))
  filtered_crash_sound = filt(bpf, crash_sound)

  filtered_crash_sound /= maximum(abs.(filtered_crash_sound))  # Normalization
  
  return filtered_crash_sound
end


# Generate the crash cymbal sound
crash_cymbal_sound = generate_crash_cymbal(sample_rate, 2.0)

# Save the crash cymbal sound to a WAV file
wavwrite(crash_cymbal_sound, "crash_cymbal.wav", Fs=sample_rate)

bass_drum_sound = bass_drum_sound[1:11025]
snare_sound = snare_sound[1:11025]

wavwrite(bass_drum_sound, "bass_drum_normalized.wav", Fs=sample_rate)

plot(bass_drum_sound, xlabel="Sample", ylabel="Amplitude", title="Bass Drum Signal")
