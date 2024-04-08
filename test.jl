#=
This example illustrates synthesizing a long tone in small pieces
and routing it to the default audio output device using `write()`.
=#

using PortAudio: PortAudioStream, write
using Gtk
using Plots;
using Sound: soundsc
include("instruments.jl")
const start_times = Dict{UInt32, UInt32}()

playNote = false;
index = 1;
freql = [523.25, 554.37, 587.33, 622.25, 659.26, 698.46, 739.99, 783.99, 830.61, 880, 932.33, 987.77]

using Gtk: GtkGrid, GtkScale, GtkWindow, GAccessor
using Gtk: signal_connect, set_gtk_property!, showall

win = GtkWindow("Sliders", 500, 200)
g = GtkGrid()
set_gtk_property!(g, :column_homogeneous, true)
push!(win, g)
showall(win)

keyboardToNote = Dict(Int('a') => 1, Int('w') => 2, Int('s') => 3, Int('e') => 4, Int('d') => 5, Int('f') => 6, Int('t') => 7, Int('g') => 8, Int('y') => 9,
                 Int('h') => 10, Int('j') => 11, Int('i') => 12, Int('k') => 13 ) 

id1 = signal_connect(win, "key-press-event") do widget, event
    k = event.keyval
    if k ∉ keys(start_times)
        start_times[k] = event.time # save the initial key press time
        println("You pressed key ", k, " which is '", Char(k), "'.")
        if(get(keyboardToNote, k, -1) != -1)
            global playNote = true;
            global index = keyboardToNote[k]
        end
    end
end

id2 = signal_connect(win, "key-release-event") do widget, event
    k = event.keyval
    start_time = pop!(start_times, k) # remove the key from the dictionary
    duration = event.time - start_time # key press duration in milliseconds
    println("You released key ", k, " after time ", duration, " msec.")
    global playNote = false;
end

stream = PortAudioStream(0, 1; warn_xruns=false)
songVec = zeros(round(Int, 7 * stream.sample_rate))
#song = 0.5 * getNote(1, 3)

function play_tone(stream, duration::Real, song::Vector; buf_size::Int = 1024)
    S = stream.sample_rate
    current = 1
    
    while current < duration*S
        amplitude = 0
        if(playNote)
          amplitude = 0.7
        end
        x = amplitude * getNote(index, 3)
        global song[current+1:current+buf_size] += x[current+1:current+buf_size];
        write(stream, song[current+1:current+buf_size])
        current += buf_size
    end
    return song
end

# songVec = play_tone(stream, 5, songVec)
# soundsc(songVec, stream.sample_rate)
# PortAudioStream(0, 1; 44100) do stream
#     write(stream, bassDrum())
#   end

