using Gtk
using Sound: soundsc
using WAV
using PortAudio: PortAudioStream, write

S = 44100
const beatN = 11025
beat = zeros(6*S) * ones(4)'

stream = PortAudioStream(0, 1; warn_xruns=false)

bass_drum, _ = wavread("bass_drum_normalized.wav")
hi_hat, _ = wavread("hihat.wav")
snare, _ = wavread("snare.wav")
crash, _ = wavread("crash_cymbal.wav")
percussion = [bass_drum, hi_hat, snare, crash]
colors = ("red", "blue", "green", "purple")
onoff = Bool.(zeros(16) * ones(4)')
amp = [3.0, 3.0, 3.0, 3.0]

function miditone(idx::Int, note::Int, g::GtkGrid, nsample::Int = beatN)
    x = percussion[note]
    write(stream,(amp[note]/10)*x) # play note so that user can hear it immediately
    if onoff[idx-2, note] == 0
        print(nsample)
        global beat[(idx-3)*nsample+1:(idx-3)*nsample+length(x), note] += x
        b_color = GtkCssProvider(data="#gocolor {background:" * colors[note] * ";}")
        push!(GAccessor.style_context(g[idx, note]), GtkStyleProvider(b_color), 600)
        set_gtk_property!(g[idx, note], :name, "gocolor")
        onoff[idx-2,note] = 1
    else
        global beat[(idx-3)*N+1:(idx-3)*N+length(x), note] -= x
        b_color = GtkCssProvider(data="#gocolor {background:none;}")
        push!(GAccessor.style_context(g[idx, note]), GtkStyleProvider(b_color), 600)
        set_gtk_property!(g[idx, note], :name, "gocolor")
        onoff[idx-2,note] = 0
    end

end

function play()
    song = (amp[1]/10)*beat[:,1] + (amp[2]/10)*beat[:,2] + (amp[3]/10)*beat[:,3] + (amp[4]/10)*beat[:,4]
    write(stream, song)
end

function getBeats()
    g = GtkGrid() # initialize a grid to hold buttons
    set_gtk_property!(g, :row_spacing, 5) # gaps between buttons
    set_gtk_property!(g, :column_spacing, 5)
    set_gtk_property!(g, :row_homogeneous, true) # stretch with window resize
    set_gtk_property!(g, :column_homogeneous, true)

    scroll = GtkScrolledWindow()

    for i in 3:18 # add the white keys to the grid
        for n in 1:4
        b = GtkButton() # make a button for this key
        signal_connect((w) -> miditone(i, n, g), b, "clicked")
        g[i, n] = b # put the button in row 2 of the grid
        end
    end

    a = GtkButton("Play Drums")
    g[1,5] = a
    signal_connect((w) -> play(), a, "clicked")
        
    names = ("Base Drum", "High Hat", "Snare", "Crash")
    for i in 1:4
        name = GtkLabel(names[i]) # make a button for this key
        g[1, i] = name # put the button in row 2 of the grid
    end

    for i in 1:4
        volume = GtkScale(false, 0:5) # make a button for this key
        g[2, i] = volume # put the button in row 2 of the grid
        GAccessor.value(volume, 3)
        signal_connect(volume, "value-changed") do widget, others...
            value = GAccessor.value(volume)
            amp[i] = value^2
        end
    end
    set_gtk_property!(scroll, :child, g)
    return scroll

# win = GtkWindow("Beat Maker",400, 300)
# push!(win, g)
# showall(win)
end

function getBeat()
    return song[:,1] + song[:,2] + song[:,3] + song[:,4]
end