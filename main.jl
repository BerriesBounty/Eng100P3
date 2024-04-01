#=
This example illustrates synthesizing a long tone in small pieces
and routing it to the default audio output device using `write()`.
=#

using PortAudio: PortAudioStream, write
using Gtk
using Plots;
using Sound: soundsc
include("BeatMaker.jl")
include("tracks.jl")
using Gtk

win = GtkWindow("Sliders", 500, 200)
g = GtkGrid()
set_gtk_property!(g, :row_spacing, 5) # gaps between buttons
set_gtk_property!(g, :column_spacing, 5)

# g_style = GtkCssProvider(data="#wb {background:blue;}")
# push!(GAccessor.style_context(g), GtkStyleProvider(g_style), 600)
# set_gtk_property!(g, :name, "wb") # set "style" of undo key
tracks = getTracks()

beatmaker = getGrid()
g2 = GtkGrid();

button_switch_to_grid2 = Gtk.Button("Go to Grid 2")
button_switch_to_grid1 = Gtk.Button("Go to Grid 1")

beatmaker[2,5] =  button_switch_to_grid2
g2[1,1] = button_switch_to_grid1

function switch_to_grid2(widget)
  hide(beatmaker)
  show(g2)
end

function switch_to_grid1(widget)
  hide(g2)
  show(beatmaker)
end

signal_connect(switch_to_grid1, button_switch_to_grid1, "clicked")
signal_connect(switch_to_grid2, button_switch_to_grid2, "clicked")

g[1,1:4] = tracks
g[1,5:8] = beatmaker
g[1, 5] = g2

push!(win, g)
showall(win)

hide(g2)
show(beatmaker)