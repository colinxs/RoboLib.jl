using Test
using MacroTools: splitstructdef
using Autotype

@autotype struct Foo{T1 <: Integer,T2} <: Number
    x1::Int
    x2::T1
    x3::T1
    x4::T2
    x5::AbstractFloat
    x6
    x7::TNotParameterized
    x8::TNotParameterized
end

@test typeof(Foo(1, 2, 3, "hello", 5.0, [], [1], [2])) == Foo{Int64,String,Float64,Array{Any,1},Array{Int64,1}}

@test_throws MethodError Foo(1, 2, 3.0, "hello", 5.0, [], [1], [2])
@test_throws MethodError Foo(1, 2, 3, "hello", 5.0, [], [1], [2.0])

@test Foo(1, 2, 3, "hello", 5.0, [], [1], [2]).x1 == 1
@test Foo(1, 2, 3, "hello", 5.0, [], [1], [2]).x2 == 2
@test Foo(1, 2, 3, "hello", 5.0, [], [1], [2]).x3 == 3
@test Foo(1, 2, 3, "hello", 5.0, [], [1], [2]).x4 == "hello"
@test Foo(1, 2, 3, "hello", 5.0, [], [1], [2]).x5 == 5.0
@test Foo(1, 2, 3, "hello", 5.0, [], [1], [2]).x6 == []
@test Foo(1, 2, 3, "hello", 5.0, [], [1], [2]).x7 == [1]
@test Foo(1, 2, 3, "hello", 5.0, [], [1], [2]).x8 == [2]
