using Gtk
using Sound: soundsc
using WAV
using PortAudio: PortAudioStream, write
include("beatmaker.jl")
S = 44100
N = 11025

song = zeros(6*S) * ones(4)'


function getTracks()
    g = GtkGrid() # initialize a grid to hold buttons
    set_gtk_property!(g, :row_spacing, 5) # gaps between buttons
    set_gtk_property!(g, :column_spacing, 5)
    set_gtk_property!(g, :row_homogeneous, true) # stretch with window resize
    set_gtk_property!(g, :column_homogeneous, true)

    for i in 2:5 # add the white keys to the grid
      b = GtkButton() # make a button for this key
      signal_connect((w) -> switchInstrument(i), b, "clicked")
      g[1, i] = b # put the button in row 2 of the grid
    end

    g2 = GtkGrid()
    set_gtk_property!(g2, :name, "track")
    g[2:18, 2:5] = g2
    return g

# win = GtkWindow("Beat Maker",400, 300)
# push!(win, g)
# showall(win)
end