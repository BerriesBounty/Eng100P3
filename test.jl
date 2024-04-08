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
slider1 = GtkScale(false, 0:10)
slider2 = GtkScale(false, 0:30)
signal_connect(slider1, "value-changed") do widget, others...
    value = GAccessor.value(slider1)
    GAccessor.value(slider2, value) # dynamic value adjustment
    println("slider value is $value")
    if value == 10
        GAccessor.range(slider1, 1, 20) # dynamic range adjustment
    end
end
g = GtkGrid()
g[1,1] = slider1
g[1,2] = slider2
set_gtk_property!(g, :column_homogeneous, true)
push!(win, g)
showall(win)

id1 = signal_connect(win, "key-press-event") do widget, event
    k = event.keyval
    if k ∉ keys(start_times)
        start_times[k] = event.time # save the initial key press time
        println("You pressed key ", k, " which is '", Char(k), "'.")
        global playNote = true;
        global index = k%length(freql) + 1
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


#song = zeros(round(Int, 20 * stream.sample_rate))
song = 0.5 * getNote(index, 2)

function play_tone(stream, duration::Real; buf_size::Int = 1024)
    S = stream.sample_rate
    current = 1
    
    while current < duration*S
        amplitude = 0
        if(playNote)
          amplitude = 0.7
        end
        x = amplitude * getNote(index, 2)
        global song[current:current+buf_size] += x[current:current+buf_size];
        write(stream, song[current:current+buf_size])
        current += buf_size
    end
end

play_tone(stream, 5)
soundsc(song, stream.sample_rate)
# PortAudioStream(0, 1; 44100) do stream
#     write(stream, bassDrum())
#   end

