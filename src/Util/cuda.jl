using CUDAnative
using CuArrays

macro gridstride(length, itersym, expr)
    quote
        index = (blockIdx().x - 1) * blockDim().x + threadIdx().x
        stride = blockDim().x * gridDim().x
        for $(esc(itersym)) = index:stride:$(esc(length))
            $(esc(expr))
        end
    end
end
