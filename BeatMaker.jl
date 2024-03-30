using Gtk
using Sound: soundsc
using WAV
using PortAudio: PortAudioStream, write

S = 44100
N = 11025
song = zeros(6*S) * ones(4)'

stream = PortAudioStream(0, 1; warn_xruns=false)

bass_drum, _ = wavread("bass_drum_normalized.wav")
hi_hat, _ = wavread("hihat.wav")
snare, _ = wavread("snare.wav")
crash, _ = wavread("crash_cymbal.wav")
percussion = [bass_drum, hi_hat, snare, crash]
colors = ("red", "blue", "green", "purple")
onoff = Bool.(zeros(16) * ones(4)')

function miditone(idx::Int, note::Int, g::GtkGrid, nsample::Int = N)
    x = percussion[note]
    write(stream, x) # play note so that user can hear it immediately
    if onoff[idx, note] == 0
        global song[(idx-1)*N+1:(idx-1)*N+length(x), note] += x
        b_color = GtkCssProvider(data="#gocolor {background:" * colors[note] * ";}")
        push!(GAccessor.style_context(g[idx, note]), GtkStyleProvider(b_color), 600)
        set_gtk_property!(g[idx, note], :name, "gocolor")
        onoff[idx,note] = 1
    else
        global song[(idx-1)*N+1:(idx-1)*N+length(x), note] -= x
        b_color = GtkCssProvider(data="#gocolor {background:none;}")
        push!(GAccessor.style_context(g[idx, note]), GtkStyleProvider(b_color), 600)
        set_gtk_property!(g[idx, note], :name, "gocolor")
        onoff[idx,note] = 0
    end

end

function play()
    beat = song[:,1] + song[:,2] + song[:,3] + song[:,4]
    write(stream, beat)
end

function getGrid()
    g = GtkGrid() # initialize a grid to hold buttons
    set_gtk_property!(g, :row_spacing, 5) # gaps between buttons
    set_gtk_property!(g, :column_spacing, 5)
    set_gtk_property!(g, :row_homogeneous, true) # stretch with window resize
    set_gtk_property!(g, :column_homogeneous, true)

    for i in 1:16 # add the white keys to the grid
        for n in 1:4
        b = GtkButton() # make a button for this key
        signal_connect((w) -> miditone(i, n, g), b, "clicked")
        g[i, n] = b # put the button in row 2 of the grid
        end
    end

    a = GtkButton("play")
    g[1,5] = a
    signal_connect((w) -> play(), a, "clicked")

    return g

# win = GtkWindow("Beat Maker",400, 300)
# push!(win, g)
# showall(win)
end