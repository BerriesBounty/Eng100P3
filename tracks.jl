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

function getTracks()
    g = GtkGrid() # initialize a grid to hold buttons
    set_gtk_property!(g, :row_spacing, 5) # gaps between buttons
    set_gtk_property!(g, :column_spacing, 5)
    set_gtk_property!(g, :row_homogeneous, true) # stretch with window resize
    set_gtk_property!(g, :column_homogeneous, true)

    for i in 1:4 # add the white keys to the grid
      b = GtkButton() # make a button for this key
      g[1, i] = b # put the button in row 2 of the grid
    end
    g2 = GtkGrid()
    g[2:9, 1:4] = g2
    return g

# win = GtkWindow("Beat Maker",400, 300)
# push!(win, g)
# showall(win)
end