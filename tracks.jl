using Gtk
using Sound: soundsc
using WAV
using PortAudio: PortAudioStream, write
include("test.jl")
include("beatmaker.jl")
S = 44100
N = 11025
playNote = false;
index = 1;

song = zeros(6*S) * ones(4)'

stream = PortAudioStream(0, 1; warn_xruns=false)

trackGridStyle = GtkCssProvider(data="#track {background:blue;}")

function play(g::GtkGrid)
  S = 44100
  bpm = 120
  bps = bpm / 60 # beats per second
  spb = 60 / bpm # seconds per beat
  t0 = 0.01 # each "tick" is this long
  tt = 0:1/S:4 # 9 seconds of ticking
  f = 440
  #x = 0.9 * cos.(2π*440*tt) .* (mod.(tt, spb) .< t0) # tone
  x = randn(length(tt)) .* (mod.(tt, spb) .< t0) / 4.5 # click via "envelope"
  write(stream, x)
end

function record(g::GtkGrid)
  S = 44100
  bpm = 120
  bps = bpm / 60 # beats per second
  spb = 60 / bpm # seconds per beat
  t0 = 0.01 # each "tick" is this long
  tt = 0:1/S:4 # 9 seconds of ticking
  f = 440
  #x = 0.9 * cos.(2π*440*tt) .* (mod.(tt, spb) .< t0) # tone
  x = randn(length(tt)) .* (mod.(tt, spb) .< t0) / 4.5 # click via "envelope"
  beat = getBeat()
  song = [x; beat];
  song = play_tone(stream, 5, song);
  write(stream, song)

end

function getTracks()
    g = GtkGrid() # initialize a grid to hold buttons
    set_gtk_property!(g, :row_spacing, 5) # gaps between buttons
    set_gtk_property!(g, :column_spacing, 5)
    set_gtk_property!(g, :row_homogeneous, true) # stretch with window resize
    set_gtk_property!(g, :column_homogeneous, true)

    playButton = GtkButton("Play")
    signal_connect((w) -> play(g), playButton, "clicked")
    g[1,1] = playButton

    recordButton = GtkButton("Record")
    signal_connect((w) -> record(g), recordButton, "clicked")
    g[3,1] = recordButton

    for i in 2:5 # add the white keys to the grid
      b = GtkButton() # make a button for this key
      g[1, i] = b # put the button in row 2 of the grid
    end

    g2 = GtkGrid()
    push!(GAccessor.style_context(g2), GtkStyleProvider(trackGridStyle), 600)
    set_gtk_property!(g2, :name, "track")
    g[2:8, 2:5] = g2
    return g

# win = GtkWindow("Beat Maker",400, 300)
# push!(win, g)
# showall(win)
end