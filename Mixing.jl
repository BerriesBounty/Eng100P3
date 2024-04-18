include("instruments.jl")
using Sound

function reverb(x)
    N=length(x)
    D = 10000
    y = x[1:N-4*D] + x[1+D:N-3*D] + x[1+2*D:N-2*D] + x[1+3*D:N-D] + x[1+4*D:N]
    return y
end

x = getNote(2,3)
x = x[1:100000]
x = reverb(x)
soundsc(x,S)
