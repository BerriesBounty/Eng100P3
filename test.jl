#=
This example illustrates synthesizing a long tone in small pieces
and routing it to the default audio output device using `write()`.
=#

using PortAudio: PortAudioStream, write

stream = PortAudioStream(0, 1; warn_xruns=false)



function play_tone(stream, freq::Real, duration::Real; buf_size::Int = 1024)
    S = stream.sample_rate
    current = 1
    while current < duration*S
        x = 0.7 * sin.(2π * (current .+ (1:buf_size)) * freq / S)
        if(current > duration*S*0.5)
          x = 0.7 * sin.(2π * (current .+ (1:buf_size)) * freq*2 / S)
        end
        write(stream, x)
        current += buf_size
    end
    nothin
end

play_tone(stream, 440, 2)