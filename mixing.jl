#=
This example illustrates synthesizing a long tone in small pieces
and routing it to the default audio output device using `write()`.
=#

using PortAudio: PortAudioStream, write
using Gtk
using Plots;
using Sound: soundsc
include("BeatMaker.jl")
using Gtk

win = GtkWindow("Sliders", 500, 200)
g = GtkGrid()

# g_style = GtkCssProvider(data="#wb {background:blue;}")
# push!(GAccessor.style_context(g), GtkStyleProvider(g_style), 600)
# set_gtk_property!(g, :name, "wb") # set "style" of undo key

g1 = getGrid()
g2 = GtkGrid();

button_switch_to_grid2 = Gtk.Button("Go to Grid 2")

push!(g1, button_switch_to_grid2)

function switch_to_grid2(widget)
  hide(g1)
  show(g2)
end

signal_connect(switch_to_grid2, button_switch_to_grid2, "clicked")

g[1,1] = g1

push!(win, g)
showall(win)
