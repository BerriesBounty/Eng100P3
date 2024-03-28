using Gtk
using Sound: soundsc

g = GtkGrid() # initialize a grid to hold buttons
set_gtk_property!(g, :row_spacing, 5) # gaps between buttons
set_gtk_property!(g, :column_spacing, 5)
set_gtk_property!(g, :row_homogeneous, true) # stretch with window resize
set_gtk_property!(g, :column_homogeneous, true)

S = 44100
N = 11025
freqs = [67; 69; 71; 73]
song = zeros(4*S) * ones(4)'

function miditone(midi::Int, idx::Int, note::Int, nsample::Int = N)
    f = 440 * 2^((midi-69)/12) # compute frequency from midi number
    x = cos.(2pi*(1:nsample)*f/S) # generate sinusoidal tone
    sound(x, S) # play note so that user can hear it immediately
    global song[(idx-1)*N+1:idx*N, note] = x
    return nothing
end

for i in 1:16 # add the white keys to the grid
    for n in 1:4
    midi = freqs[n]
    b = GtkButton() # make a button for this key
    signal_connect((w) -> miditone(midi, i, n), b, "clicked")
    g[i, n] = b # put the button in row 2 of the grid
    end
end

function play()
    beat = song[:,1] + song[:,2] + song[:,3] + song[:,4]
    soundsc(beat, S)
end

a = GtkButton("play")
g[1,5] = a
signal_connect((w) -> play(), a, "clicked")

win = GtkWindow("Beat Maker",400, 300)
push!(win, g)
showall(win)

print(size(song))