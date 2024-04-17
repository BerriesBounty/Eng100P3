using PortAudio: PortAudioStream; write
using Gtk
using Plots
using Sound: soundsc
include("instruments.jl")

Trial1 = [17 20300 1; 19 19600 2; 21 19600 3; 23 20300 4; 25 16800 5; 27 18900 6; 29 18200 7; 30 21000 8; 32 20300 9; 35 15400 10; 36 20300 11; 38 17500 12; 40 21000 13]
Trial2 = [17 11025 1; 19 11025 2; 21 11025 3; 23 11025 4; 25 11025 5; 27 11025 6; 29 11025 7; 31 11025 8; 33 11025 9; 35 11025 10; 37 11025 11; 39 11025 12; 41 11025 13]
Trial3 = [17 22050 1; 19 22050 2; 21 22050 3; 23 22050 4; 25 11025 5; 27 11025 6; 28 11025 7; 28 11025 8; 28 33075 9; 31 22050 10; 33 22050 11; 35 22050 12; 37 22050 13]

scatter(Trial1[:][27:39].+78, xlabel="Note number", ylabel="Midi Number", title="Midi number of 13 note played", )
scatter!(Trial2[:][27:39].+78, xlabel="Note number", ylabel="Midi Number", title="Midi number of 13 note played", )
scatter!(Trial3[:][27:39].+78, xlabel="Note number", ylabel="Midi Number", title="Midi number of 13 note played", )
