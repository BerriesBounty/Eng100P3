#DELETE
using PortAudio.LibPortAudio
include("percussion.jl")

mutable struct AudioData
    n::Int
    out::Ptr{Float32}
    in::Ptr{Float32}
    offset::Ptr{Cint}
end

function portaudio_callback(inputbuffer, outputbuffer, framecount, timeinfo, statusflags, userdata)::Cint

    audiodata = unsafe_load(Ptr{AudioData}(userdata))
    offset = unsafe_load(audiodata.offset)
    n = audiodata.n

    for i in 1:framecount
        ind = offset + i
        unsafe_store!(outputbuffer, ind > n ? 0f0 : unsafe_load(audiodata.out, ind), i)
        ind <= n && unsafe_store!(audiodata.in, unsafe_load(inputbuffer, i), ind)
    end

    new_offset = offset + framecount
    unsafe_store!(audiodata.offset, new_offset)

    return new_offset > n ? 1 : 0
end

cfunc = @cfunction portaudio_callback Cint (
    Ptr{Float32},
    Ptr{Float32},
    Culong,
    Ptr{LibPortAudio.PaStreamCallbackTimeInfo},
    LibPortAudio.PaStreamCallbackFlags,
    Ptr{Cvoid}
)

macro checkerr(exp)
    quote
        errcode = $(esc(exp))
        e = LibPortAudio.PaErrorCode(errcode)
        if e != LibPortAudio.paNoError
            error("PortAudio errored with status code $errcode ($(string(e)))")
        end
    end
end

@info "Initializing PortAudio"
@checkerr LibPortAudio.Pa_Initialize()
mutable_pointer = Ref{Ptr{LibPortAudio.PaStream}}(0)
n_in = 1
n_out = 1
samplerate = 44100
framecount = 256

signal = Float32.(sin.(2pi*440*(1:samplerate*4)/samplerate) + sin.(2pi*550*(1:samplerate*4)/samplerate))
recording = similar(signal)
offset = Cint[0]
audiodata = AudioData(
    length(signal),
    Base.unsafe_convert(Ptr{Float32}, signal),
    Base.unsafe_convert(Ptr{Float32}, recording),
    Base.unsafe_convert(Ptr{Cint}, offset)
)

@checkerr LibPortAudio.Pa_OpenDefaultStream(
    mutable_pointer,
    n_in,
    n_out,
    LibPortAudio.paFloat32,
    samplerate,
    framecount,
    cfunc,
    Ref(audiodata),
)

pointer_to = mutable_pointer[]

try
    @info "Starting stream"
    @checkerr LibPortAudio.Pa_StartStream(pointer_to)
    # wait for the cfunction to return 1
    while LibPortAudio.Pa_IsStreamActive(pointer_to) == 1
        sleep(1/10)
    end
finally
    @info "Stopping stream"
    @checkerr LibPortAudio.Pa_StopStream(pointer_to)
    @info "Terminating PortAudio"
    @checkerr LibPortAudio.Pa_Terminate()
end

PortAudioStream(0, 1; samplerate) do stream
  write(stream, recording)
end