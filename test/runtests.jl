using Test

@testset "CircularArray" begin
    using RoboLib.Util

    @testset "Core Functionality" begin
        arr = rand(3,5,10)
        cb = CircularArray(arr)
        @testset "When empty" begin
            @test length(cb) == 0
            @test capacity(cb) == 10
            @test isempty(cb)
            @test !isfull(cb)
        end

        @testset "With 1 element" begin
            put!(cb, rand(3,5))
            @test length(cb) == 1
            @test capacity(cb) == 10
            @test !isfull(cb)
        end

    end

    @testset "access" begin
        arr = rand(3,5,10)
        cb = CircularArray(arr)  # New, empty one for full test coverageI
        inputs = [rand(3,5) for _ in 1:10]
        for (idx, input) in enumerate(inputs)
            put!(cb, input)
            @test length(cb) == idx
        end

        @test capacity(cb) == 10
        @test !isempty(cb)
        @test isfull(cb)

        for (idx, input) in enumerate(inputs)
            @test cb[idx] == input
        end

        for input in inputs
            @test fetch(cb) == input
            @test take!(cb) == input
        end

    end

    @testset "inplace" begin
        arr = rand(3,5,10)
        cb = CircularArray(arr)  # New, empty one for full test coverageI
        inputs = [rand(3,5) for _ in 1:10]
        for input in inputs
            put!(cb, input)
        end

        out = rand(3,5)
        for input in inputs
            fetch(cb, out)
            @test out == input
            out .= 0.0
            take!(cb, out)
            @test out == input
        end
    end

    @testset "async" begin
        arr = rand(3,5,10)
        cb = CircularArray(arr)  # New, empty one for full test coverageI
        inputs = [rand(3,5) for _ in 1:10]

        out1 = zeros(3,5)
        out2 = zeros(3,5)
        @async take!(cb, out1)
        @async take!(cb, out2)

        sleep(0.5)

        @test iszero(out1)
        @test iszero(out2)
        put!(cb, inputs[1])
        put!(cb, inputs[2])
        sleep(0.5)
        @test out1 == inputs[2] && out2 == inputs[1] || out2 == inputs[2] && out1 == inputs[1]

        @test isempty(cb)

        out1 = zeros(3,5)
        out2 = zeros(3,5)
        @async fetch(cb, out1)
        @async fetch(cb, out2)
        @test iszero(out1)
        @test iszero(out2)
        put!(cb, inputs[3])
        sleep(2)
        println(out1, out2)
        @test out1 == inputs[3]
        @test out2 == inputs[3]

        @test length(cb) == 1

    end


end