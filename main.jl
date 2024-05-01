#=
This example illustrates synthesizing a long tone in small pieces
and routing it to the default audio output device using `write()`.
=#

using PortAudio: PortAudioStream, write
using Gtk
using Plots;
using Sound: soundsc
using DSP
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
playSynth = false;
isOctaveUp = false;
recordIndex = Array{Int, 2}(undef, 0, 4)
recordingStartTime = 1
noteStartTime = 1
curInstrument = 1
cur = 1
index = -1
lastIndex = -1
isTremolo = zeros(4)
stream = PortAudioStream(0, 1; warn_xruns=false)
S = 44100
#keyboard pressing-----------------------
keyboardToNote = Dict(Int('a') => 1, Int('w') => 2, Int('s') => 3, Int('e') => 4, Int('d') => 5, Int('f') => 6, Int('t') => 7, Int('g') => 8, Int('y') => 9,
                 Int('h') => 10, Int('j') => 11, Int('i') => 12, Int('k') => 13 ) 
instrumentRecordings = zeros((Int)(8*S)) * ones(4)'

id1 = signal_connect(win, "key-press-event") do widget, event
  k = event.keyval
  if k ∉ keys(start_times)
      start_times[k] = event.time # save the initial key press time
      #println("You pressed key ", k, " which is '", Char(k), "'.")
      if(Char(k)=='q')
        global isOctaveUp = true
        print(Char(k))
      end
      if(get(keyboardToNote, k, -1) != -1)
          if(recording)
            if(index == -1)
              global noteStartTime = cur
            else
              duration = max(round(Int, (cur - noteStartTime )/(beatN)),1) * beatN
              startIndex = round(Int, noteStartTime/(beatN), RoundDown)
              if(startIndex == lastIndex)
                startIndex += 1
              end
              global recordIndex = vcat(recordIndex, [startIndex duration index isOctaveUp])
              global noteStartTime = cur
              global lastIndex = startIndex
            end
          end
          global index = keyboardToNote[k]
          global CurrentNote = getNote(index, curInstrument)
          global playNote = true
          
          if(canPlay)  
            play_tone()
          end
      end
  else
    # if(index == -1)
    #   global index = keyboardToNote[k]
    #   global playNote = true
    #   if(canPlay)  
    #     play_tone()
    #   end
    # end
  end
end

id2 = signal_connect(win, "key-release-event") do widget, event
  k = event.keyval
  start_time = pop!(start_times, k) # remove the key from the dictionary
  duration = event.time - start_time # key press duration in milliseconds
  #println("You released key ", k, " after time ", duration, " msec.")
  if(Char(k)=='q')
    global isOctaveUp = false
  end
  if(Char(k)!='q' && keyboardToNote[k] == index)
    if(recording)
      duration = max(round(Int, (cur - noteStartTime )/(beatN)),1) * beatN
      startIndex = round(Int, noteStartTime/(beatN), RoundDown)
      if(startIndex == lastIndex)
        startIndex += 1
      end
      global recordIndex = vcat(recordIndex, [startIndex duration index isOctaveUp])
      global lastIndex = startIndex
    end
    global index = -1
    global current = 0
  end
end

function play(g::GtkGrid)
  ir = copy(instrumentRecordings)
  for i in 1:4
    if(isTremolo[i]==1)
      ir[:, i] = filterOn(ir[:, i])
    end
  end
  song = ir[:,1] .+ ir[:,2] .+ ir[:,3] .+ ir[:,4]
  song = [song; zeros(2*S)]
  song += getBeat()
  write(stream, song)
  
end

function filterOn(i)
  # s = i
  # N = length(s)
  # S = 44100
  # t = N/S
  # lfo =  0.5 - 0.4 * cos.(2π*5*t)
  # s = s.*lfo
  lpf = digitalfilter(Lowpass(100; fs=44100), Butterworth(2))
  filtered_signal = filt(lpf, i)
  max_amp = maximum(abs.(filtered_signal))
  normalized_signal = filtered_signal / max_amp
  return normalized_signal
end

function setFilter(i, grid)
  
  if(isTremolo[i]==0)
    b_color = GtkCssProvider(data="#nocolor {background:gray;}")
    push!(GAccessor.style_context(grid[7, i]), GtkStyleProvider(b_color), 600)
    set_gtk_property!(grid[7, i], :name, "nocolor")
    isTremolo[i] = 1
  else
    b_color = GtkCssProvider(data="#nocolor {background:none;}")
    push!(GAccessor.style_context(grid[7, i]), GtkStyleProvider(b_color), 600)
    set_gtk_property!(grid[7, i], :name, "nocolor")
    isTremolo[i] = 0
  end
end

function record()
  global recordIndex = Array{Int, 2}(undef, 0, 4)
  global canPlay = false;
  global recording = true;
  S = 44100
  bpm = 60
  bps = bpm / 60 # beats per second
  spb = 60 / bpm # seconds per beat
  t0 = 0.01 # each "tick" is this long
  tt = 0:1/S:4 # 9 seconds of ticking
  f = 440
  #x = 0.9 * cos.(2π*440*tt) .* (mod.(tt, spb) .< t0) # tone
  x = randn(length(tt)) .* (mod.(tt, spb) .< t0) / 4.5 # click via "envelope"
  beat = getBeat()
  song = [x; beat; zeros(2*S)];
  ir = copy(instrumentRecordings)
  for i in 1:4
    if(isTremolo[i]==1)
      ir[:, i] = filterOn(ir[:, i])
    end
  end
  song[length(x)+1:length(song)-4*S] .+= ir[:,1] .+ ir[:,2] .+ ir[:,3] .+ ir[:,4]
  global cur = 1
  @async begin
    while cur < 12*S
        amplitude = 0
        if(index!=-1 && curInstrument!=5)
          amplitude = 0.7
          x = amplitude * getNote(index, curInstrument)
          if(isOctaveUp)
            x = x[1:2:length(x)]
          end
          if(playSynth)
            song[cur+1:cur+buf_size] += x[cur+1:cur+buf_size]
          end
        end
        write(stream, song[cur+1:cur+buf_size])
        cur += buf_size
    end
    
    global canPlay = true;
    global recording = false;
    print(recordIndex)
    for i in 1:size(recordIndex)[1]
      if(recordIndex[i, 1] <= 16) 
        continue
      end
      x = 0.7 * getNote(recordIndex[i, 3], curInstrument)
      if(recordIndex[i, 4] != 0)
        x = x[1:2:length(x)]
      end
      X = x[1:recordIndex[i,2]]
      t = (1:length(X)) ./44100
      env = 1 .- exp.(60*(t.-length(X)/44100))
      X .*= env
      instrumentRecordings[(recordIndex[i, 1]-17)*(beatN)+1:(recordIndex[i, 1]-17)*(beatN)+recordIndex[i, 2], curInstrument] += X
    end
  end
  
end

function switchInstrument(i, grid)
  b_color = GtkCssProvider(data="#nocolor {background:none;}")
  push!(GAccessor.style_context(grid[1, curInstrument]), GtkStyleProvider(b_color), 600)
  set_gtk_property!(grid[1, curInstrument], :name, "nocolor")
  global curInstrument = i;
  b_color = GtkCssProvider(data="#bcolor {background:gray;}")
  push!(GAccessor.style_context(grid[1, i]), GtkStyleProvider(b_color), 600)
  set_gtk_property!(grid[1, i], :name, "bcolor")
  if(i==5)
    switch_to_grid1()
  else
    switch_to_grid2()
  end
end

function clearInstrument(i)
  instrumentRecordings[:, i] .= 0
end

function getTracks()
  names = ("Electric Guitar", "Trumpet", "Clarinet", "Tone","Drum")
  g = GtkGrid() # initialize a grid to hold buttons
  set_gtk_property!(g, :row_spacing, 5) # gaps between buttons
  set_gtk_property!(g, :column_spacing, 5)

  for i in 1:5 # add the white keys to the grid
    b = GtkButton(names[i]) # make a button for this key
    signal_connect((w) -> switchInstrument(i, g), b, "clicked")
    g[1:3, i] = b # put the button in row 2 of the grid
  end

  for i in 1:5 # add the white keys to the grid
    b = GtkButton("clear") # make a button for this key
    signal_connect((w) -> clearInstrument(i), b, "clicked")
    g[4:6, i] = b # put the button in row 2 of the grid
  end

  for i in 1:4 # add the white keys to the grid
    b = GtkButton("Add Filters") # make a button for this key
    signal_connect((w) -> setFilter(i, g), b, "clicked")
    g[7:9, i] = b # put the button in row 2 of the grid
  end

  return g

end

function download()
  ir = copy(instrumentRecordings)
  for i in 1:4
    if(isTremolo[i]==1)
      ir[:, i] = filterOn(ir[:, i])
    end
  end
  song = ir[:,1] + ir[:,2] + ir[:,3] + ir[:,4]
  song = [song; zeros(2*S)]
  song += getBeat()
  wavwrite(song, "result.wav", Fs=44100)
end

function toggleSynth(grid)
  global playSynth = !playSynth
  if(playSynth)
    b_color = GtkCssProvider(data="#synthcolor {background:gray;}")
    push!(GAccessor.style_context(grid[4, 1]), GtkStyleProvider(b_color), 600)
    set_gtk_property!(grid[4, 1], :name, "synthcolor")
  else
    b_color = GtkCssProvider(data="#synthcolor {background:none;}")
    push!(GAccessor.style_context(grid[4, 1]), GtkStyleProvider(b_color), 600)
    set_gtk_property!(grid[4, 1], :name, "synthcolor")
  end
end

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
topBar[2, 1] = recordButton

downloadButton = GtkButton("Download")
signal_connect((w) -> download(), downloadButton, "clicked")
topBar[3, 1] = downloadButton

playSynthButton = GtkButton("Play Synth on Record")
signal_connect((w) -> toggleSynth(topBar), playSynthButton, "clicked")
topBar[4:5, 1] = playSynthButton
g[1:3,1] = topBar



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
    while index != -1
      amplitude = 0.7
      x = amplitude * getNote(index, curInstrument)
      if(isOctaveUp)
        x = x[1:2:length(x)]
      end
      write(stream, x[current+1:current+buf_size])
      global current += buf_size
    end
  end 
end

x = getNote(1,1);
y = filterOn(x)
plot(y[1:44100], xlabel="samples", ylabel="amplitude", title="Filtered Signal")