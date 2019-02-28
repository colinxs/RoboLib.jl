"""
Savitzky-Golay filter of window half-width M and degree N

M is the number of points before and after to interpolate, i.e. the full width
of the window is 2M+1

CT is the savgol coefficient dtype
T is the datatype of your input Vector
TO is the output type (the type of CT * T)
    ex: if CT is Float64, and T is Float32, TO is Float64

Padding is done by repeating the first and last elements.
i.e. for a M = 2, smoothed[1] = c1*data[1] c2*data[1] c3*data[2]

"""

# TODO add test

struct SavitzkyGolayFilter{M,N,CT,TO}
    _buf::Vector{TO}
    function SavitzkyGolayFilter{M,N,CT,T}() where {M,N,CT,T}
        TO = Base.promote_op(*, CT, T)
        new{M,N,CT,TO}(Vector{TO}())
    end
end

# TODO add proper padding
@generated function (s::SavitzkyGolayFilter{M,N,CT,TO})(data::AbstractVector{T}) where {M,N,CT,TO,T}

     # create Jacobian matrix
     J = zeros(CT, 2M+1, N+1)
     for i=1:2M+1, j=1:N+1
         J[i, j] = (i-M-1)^(j-1)
     end
     e₁ = zeros(CT, N+1)
     e₁[1] = CT(1.0)

     # compute filter coefficients
     C = J' \ e₁
     @assert eltype(C) == CT

     # evaluate filter on data matrix
     expr = quote
         n = size(data, 1)
         smoothed = resize!(s._buf, n)
         @inbounds @simd for i in M+1:n-M
             smoothed[i] = $(C[M+1])*data[i]
         end

         @inbounds @simd for i in 1:M
             smoothed[i] = $(C[M+1])*data[1]
             smoothed[end+1-i] = $(C[M+1])*data[end]
         end
         smoothed
     end

    for j=1:M
        push!(expr.args[6].args[3].args[3].args[2].args,
           :(smoothed[i] += $(C[M+1-j])*data[i-$j])
        )
        push!(expr.args[6].args[3].args[3].args[2].args,
           :(smoothed[i] += $(C[M+1+j])*data[i+$j])
        )
    end

    # front padding
    for j=1:M
        push!(expr.args[8].args[3].args[3].args[2].args,
            quote
                if i - $j >= 1
                    smoothed[i] += $(C[M+1-j])*data[i-$j]
                else
                    smoothed[i] += $(C[M+1-j])*data[1]
                end
            end
        )
        push!(expr.args[8].args[3].args[3].args[2].args,
           :(smoothed[i] += $(C[M+1+j])*data[i+$j])
        )
    end

    # end padding
    push!(expr.args[8].args[3].args[3].args[2].args,
        :(idx = n - i + 1)
    )
    for j=1:M
        push!(expr.args[8].args[3].args[3].args[2].args,
            quote
                if idx + $j <= n
                    smoothed[idx] += $(C[M+1-j])*data[idx+$j]
                else
                    smoothed[idx] += $(C[M+1-j])*data[end]
                end
            end
        )
        push!(expr.args[8].args[3].args[3].args[2].args,
           :(smoothed[idx] += $(C[M+1+j])*data[idx-$j])
        )
    end



     return expr
end
