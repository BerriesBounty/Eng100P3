#=
This example illustrates synthesizing a long tone in small pieces
and routing it to the default audio output device using `write()`.
=#

using PortAudio: PortAudioStream, write
using Gtk
using Plots;
using Sound: soundsc
include("instruments.jl")
using Gtk

win = GtkWindow("Sliders", 500, 200)
g = GtkGrid()

g_style = GtkCssProvider(data="#wb {background:blue;}")
push!(GAccessor.style_context(g), GtkStyleProvider(g_style), 600)
set_gtk_property!(g, :name, "wb") # set "style" of undo key

button1 = GtkButton()
g[1,1] = button1
set_gtk_property!(g, :column_homogeneous, true)
push!(win, g)

g2 = GtkGrid()
button2 = GtkButton()
g2[1,1] = button2
set_gtk_property!(g2, :column_homogeneous, true)
push!(win, g2)
showall(win)
