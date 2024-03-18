#=
This example illustrates synthesizing a long tone in small pieces
and routing it to the default audio output device using `write()`.
=#

using PortAudio: PortAudioStream, write
using Gtk
include("percussion.jl")
const start_times = Dict{UInt32, UInt32}()

playNote = false;
index = 1;
freql = [440, 480, 520, 560]

w = GtkWindow("Key Press/Release Example")

id1 = signal_connect(w, "key-press-event") do widget, event
    k = event.keyval
    if k ∉ keys(start_times)
        start_times[k] = event.time # save the initial key press time
        println("You pressed key ", k, " which is '", Char(k), "'.")
        global playNote = true;
        global  index = k%4 + 1
    else
        println(playNote)
    end
end

id2 = signal_connect(w, "key-release-event") do widget, event
    k = event.keyval
    start_time = pop!(start_times, k) # remove the key from the dictionary
    duration = event.time - start_time # key press duration in milliseconds
    println("You released key ", k, " after time ", duration, " msec.")
    global playNote = false;
end

stream = PortAudioStream(0, 1; warn_xruns=false)

function play_tone(stream, freq::Real, duration::Real; buf_size::Int = 1024)
    S = stream.sample_rate
    current = 1
    
    while current < duration*S
        println(playNote)
        amplitude = 0.0001
        freq1 = freql[index];
        if(playNote)
          amplitude = 0.7
        end
        x = amplitude * sin.(2π * (current .+ (1:buf_size)) * freq1*2 / S)
        write(stream, x)
        current += buf_size
    end
    nothing
end

#play_tone(stream, 440, 20)

PortAudioStream(0, 1; 44100) do stream
    write(stream, bassDrum())
  end

