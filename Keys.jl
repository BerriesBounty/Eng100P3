using Gtk

function getKeys()
    g = GtkGrid() # initialize a grid to hold buttons
    set_gtk_property!(g, :row_spacing, 5) # gaps between buttons
    set_gtk_property!(g, :column_spacing, 5)
    set_gtk_property!(g, :row_homogeneous, true) # stretch with window resize
    set_gtk_property!(g, :column_homogeneous, true)
    sharp = GtkCssProvider(data="#wb {color:white; background:black;}")

    white = ["G" "A"; "A" "S"; "B" "D"; "C" "F"; "D" "G"; "E" "H"; "F" "J"; "G" "K" ]
    black = ["G#" "W" 4; "A#" "E" 6; "C#" "T" 10; "D#" "Y" 12; "F#" "I" 16]
    for i in 1:5 # add the black keys to the grid
        note, key, start = black[i,1:3]
        b = GtkButton(note*"($key)") # make a button for this key
        #signal_connect((w) -> miditone(midi), b, "clicked") # callback
        push!(GAccessor.style_context(b), GtkStyleProvider(sharp), 600)
        set_gtk_property!(b, :name, "wb") # set "style" of black key
        g[start:start+1, 1:2] = b # put the button in row 2 of the grid
    end
    for i in 1:8 # add the white keys to the grid
        note, key = white[i,1:2]
        b = GtkButton(note*"($key)") # make a button for this key
        #signal_connect((w) -> miditone(midi), b, "clicked") # callback
        g[3+(i-1)*2:4+(i-1)*2, 1:5] = b # put the button in row 2 of the grid
    end

    names = ("Base Drum", "High Hat", "Snare", "Crash")
    for i in 1:4
        name = GtkLabel(names[i]) # make a button for this key
        g[1, i] = name # put the button in row 2 of the grid
    end

    amp = [3.0, 3.0, 3.0, 3.0]

    for i in 1:4
        volume = GtkScale(false, 1:5) # make a button for this key
        g[2, i] = volume # put the button in row 2 of the grid
        GAccessor.value(volume, 3)
        signal_connect(volume, "value-changed") do widget, others...
            value = GAccessor.value(volume)
            amp[i] = value^2
        end
    end


#win = GtkWindow("Beat Maker",400, 300)
#push!(win, g)
#showall(win)
   return g
end

b_color = GtkCssProvider(data="#gocolor {background:" * colors[i] * ";}")
push!(GAccessor.style_context(g[2:3, i]), GtkStyleProvider(b_color), 600)
set_gtk_property!(g[2:3, i], :name, "gocolor")

colors = ("red", "green", "blue", "purple", "yellow")


