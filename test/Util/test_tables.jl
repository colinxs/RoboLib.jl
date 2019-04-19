using Test
using JuliaDB
using RoboLib.Util
using Dates

function test_join_asof_basic()
    t1 = [-10, 1.51, 2.49, 4, 10]
    x1 = ['a', 'b', 'c', 'd', 'e']
    t2 = [1, 2, 3, 4, 5]
    x2 = ['a', 'b', 'c', 'd', 'e']

    t1 = table((t=t1, x1=x1))
    t2 = table((t=t2, x2=x2))
    comb = join_asof(t1, t2, key=:t)

    x2_corr = ['a', 'b', 'b', 'd', 'e']
    x2_synced = select(comb, :x2)

    x2_corr == x2_synced
    return t1
end

@testset "Tables Basic" begin
    t1 = [-10, 1.51, 2.49, 4, 10]
    x1 = ['a', 'b', 'c', 'd', 'e']
    t2 = [1, 2, 3, 4, 5]
    x2 = ['a', 'b', 'c', 'd', 'e']
    tbl1 = table((t=t1, x1=x1))
    tbl2 = table((t=t2, x2=x2))

    # basic join_asof
    @test begin
        comb = join_asof(tbl1, tbl2, key=:t)
        x2_corr = ['a', 'b', 'b', 'd', 'e']
        x2_synced = select(comb, :x2)
        x2_corr == x2_synced
    end

    @test (Float64, Char) == coltypes(tbl1)
    @test (:foo__t, :x1) == colnames(prefix(tbl1, "foo", exclude=(:x1,), delim="__"))
    @test (:t__foo, :x1) == colnames(postfix(tbl1, "foo", exclude=(:x1,), delim="__"))
    @test setpkey(tbl1, :x1).pkey == [2]
    @test reltime(table((t=[Millisecond(i + 10) for i in 1:5],)), timekey=:t) == table((t=[Millisecond(i) for i in 0:4],))
    @test dedup(table((x=[1,2,2,3],y=['a','b','c','d'])), :x) == table((x=[1,2,3],y=['a','b','d']))
end