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