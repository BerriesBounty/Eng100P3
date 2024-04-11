#=
This example illustrates synthesizing a long tone in small pieces
and routing it to the default audio output device using `write()`.
=#

using PortAudio: PortAudioStream, write
using Gtk
using Plots;
using Sound: soundsc
include("BeatMaker.jl")
include("Keys.jl")
include("test.jl")
using Gtk
win = GtkWindow("Sliders", 400, 200)
g = GtkGrid()
set_gtk_property!(g, :row_spacing, 5) # gaps between buttons
set_gtk_property!(g, :column_spacing, 5)
set_gtk_property!(g, :row_homogeneous, true) # stretch with window resize
set_gtk_property!(g, :column_homogeneous, true)

playNote = false;
canPlay = true;
recording = false;
curInstrument = 1;
index = 1;
stream = PortAudioStream(0, 1; warn_xruns=false)
#keyboard pressing-----------------------
keyboardToNote = Dict(Int('a') => 1, Int('w') => 2, Int('s') => 3, Int('e') => 4, Int('d') => 5, Int('f') => 6, Int('t') => 7, Int('g') => 8, Int('y') => 9,
                 Int('h') => 10, Int('j') => 11, Int('i') => 12, Int('k') => 13 ) 
id1 = signal_connect(win, "key-press-event") do widget, event
  k = event.keyval
  if k ∉ keys(start_times)
      start_times[k] = event.time # save the initial key press time
      println("You pressed key ", k, " which is '", Char(k), "'.")
      if(get(keyboardToNote, k, -1) != -1)
          global index = keyboardToNote[k]
          if(canPlay)
            global playNote = true;
            play_tone()
          end
      end
  end
end

id2 = signal_connect(win, "key-release-event") do widget, event
  k = event.keyval
  start_time = pop!(start_times, k) # remove the key from the dictionary
  duration = event.time - start_time # key press duration in milliseconds
  println("You released key ", k, " after time ", duration, " msec.")
  global playNote = false
  global current = 0
end

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

function record()
  canPlay = false;
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
  cur = 1
  @async begin
    while cur < 16*S
        amplitude = 0
        if(playNote)
          amplitude = 0.7
        end
        x = amplitude * getNote(index, curInstrument)
        global song[cur+1:cur+buf_size] += x[cur+1:cur+buf_size];
        write(stream, song[cur+1:cur+buf_size])
        cur += buf_size
    end
    return song
  end
end

function switchInstrument(i)
  global curInstrument = i;
  if(i==5)
    switch_to_grid1()
  else
    switch_to_grid2()
  end
end

function getTracks()
  names = ("Piano", "Sax", "Flute", "Tuba","Drum")
  g = GtkGrid() # initialize a grid to hold buttons
  set_gtk_property!(g, :row_spacing, 5) # gaps between buttons
  set_gtk_property!(g, :column_spacing, 5)

  for i in 1:5 # add the white keys to the grid
    b = GtkButton(names[i]) # make a button for this key
    signal_connect((w) -> switchInstrument(i), b, "clicked")
    g[2:3, i] = b # put the button in row 2 of the grid
  end



  g2 = GtkGrid()
  set_gtk_property!(g2, :name, "track")
  g[3, 2:5] = g2
  return g

end

# g_style = GtkCssProvider(data="#wb {background:blue;}")
# push!(GAccessor.style_context(g), GtkStyleProvider(g_style), 600)
# set_gtk_property!(g, :name, "wb") # set "style" of undo key
tracks = getTracks()
beatmaker = getBeats()
keyboard = getKeys()

topBar = GtkGrid()
set_gtk_property!(topBar, :row_spacing, 5) # gaps between buttons
playButton = GtkButton("Play")
signal_connect((w) -> play(g), playButton, "clicked")
topBar[1, 1] = playButton

recordButton = GtkButton("Record")
signal_connect((w) -> record(), recordButton, "clicked")
topBar[3, 1] = recordButton
g[1,1] = topBar

keyboard[1,5] = button_switch_to_grid1

function switch_to_grid2()
  hide(beatmaker)
  show(keyboard)
end

function switch_to_grid1()
  hide(keyboard)
  show(beatmaker)
end


g[1:10,2:5] = tracks
g[1:10,6:9] = beatmaker
g[1:10,6:9] = keyboard

push!(win, g)
showall(win)

show(keyboard)
hide(beatmaker)

function play_tone()
  @async begin
    while playNote
      if (playNote)
        amplitude = 0.7
        x = amplitude * getNote(index, curInstrument)
        write(stream, x[current+1:current+buf_size])
        global current += buf_size
      end
    end
  end 
end