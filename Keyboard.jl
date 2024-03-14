using Gtk
using Sound: sound
using MAT: matwrite

# initialize two global variables used throughout
S = 7999 # sampling rate (samples/second) for this low-fi project
song = Float32[] # initialize "song" as an empty vector

function miditone(midi::Int; nsample::Int = 2000)
    f = 440 * 2^((midi-69)/12) # compute frequency from midi number
    x = cos.(2pi*(1:nsample)*f/S) # generate sinusoidal tone
    sound(x, S) # play note so that user can hear it immediately
    global song = [song; x] # append note to the (global) song vector
    return nothing
end

# define the white and black keys and their midi numbers - FIXME!
white = ["G" 67; "A" 69; "B" 71; "C" 72; "D" 74; "E" 76; "F" 77; "G" 79 ]
black = ["G" 68 2; "A" 70 4; "C" 73 8; "D" 75 10; "F" 78 14]

g = GtkGrid() # initialize a grid to hold buttons
set_gtk_property!(g, :row_spacing, 5) # gaps between buttons
set_gtk_property!(g, :column_spacing, 5)
set_gtk_property!(g, :row_homogeneous, true) # stretch with window resize
set_gtk_property!(g, :column_homogeneous, true)

# define the "style" of the black keys
sharp = GtkCssProvider(data="#wb {color:white; background:black;}")
# FIXME! add a style for the end button
endStyle = GtkCssProvider(data="#wb {color:yellow; background:blue;}")
undoStyle = GtkCssProvider(data="#wb {color:black; background:yellow;}")
clearStyle = GtkCssProvider(data="#wb {color:white; background:red;}")
restStyle = GtkCssProvider(data="#wb {color:white; background:green;}")

for i in 1:size(white,1) # add the white keys to the grid
    key, midi = white[i,1:2]
    b = GtkButton(key) # make a button for this key
    signal_connect((w) -> miditone(midi), b, "clicked") # callback
    g[(1:2) .+ 2*(i-1), 2] = b # put the button in row 2 of the grid
end
for i in 1:size(black,1) # add the black keys to the grid
    key, midi, start = black[i,1:3]
    b = GtkButton(key * "♯") # to make ♯ symbol, type \sharp then hit <tab>
    push!(GAccessor.style_context(b), GtkStyleProvider(sharp), 600)
    set_gtk_property!(b, :name, "wb") # set "style" of black key
    signal_connect((w) -> miditone(midi), b, "clicked") # callback
    g[start .+ (0:1), 1] = b # put the button in row 1 of the grid
end

#functions for the buttons clicked --------------
function end_button_clicked(w) # callback function for "end" button
    println("The end button")
    sound(song, S) # play the entire song when user clicks "end"
    matwrite("proj1.mat", Dict("song" => song); compress=true) # save song to file
end

function undo_button_clicked(w)
    println("The undo button")
    global song = song[1:(length(song)-2000)]
end

function clear_button_clicked(w)
    println("The reset button")
    global song = [];
end

function rest_button_clicked(w)
    println("The rest button")
    x = 0.00001 * cos.(2pi*(1:2000)*10/S) # generate sinusoidal tone
    global song = [song; x]
end


ebutton = GtkButton("end") # make an "end" button
g[1:4, 3] = ebutton # fill up half of row 3 of grid
push!(GAccessor.style_context(ebutton), GtkStyleProvider(endStyle), 600)
set_gtk_property!(ebutton, :name, "wb") # set "style" of end button
signal_connect(end_button_clicked, ebutton, "clicked") # callback

undo = GtkButton("undo") # make an "undo" button
g[9:12, 3] = undo # fill up 1/4 of row 3 of grid
push!(GAccessor.style_context(undo), GtkStyleProvider(undoStyle), 600)
set_gtk_property!(undo, :name, "wb") # set "style" of undo key
signal_connect(undo_button_clicked, undo, "clicked") # callback

cbutton = GtkButton("clear") # make a "clear" button
g[13:16, 3] = cbutton # fill up 1/4 of row 3 of grid
push!(GAccessor.style_context(cbutton), GtkStyleProvider(clearStyle), 600)
set_gtk_property!(cbutton, :name, "wb") # set "style" of reset key
signal_connect(clear_button_clicked, cbutton, "clicked")

rbutton = GtkButton("rest") # make a "rest" button
g[5:8, 3] = rbutton # fill up 1/4 of row 3 of grid
push!(GAccessor.style_context(rbutton), GtkStyleProvider(restStyle), 600)
set_gtk_property!(rbutton, :name, "wb") # set "style" of rest key
signal_connect(rest_button_clicked, rbutton, "clicked")

win = GtkWindow("gtk3", 400, 300) # 400×300 pixel window for all the buttons
push!(win, g) # put button grid into the window
showall(win); # display the window full of buttons
