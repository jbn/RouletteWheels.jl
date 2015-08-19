using RouletteWheels
using Base.Test
using Compat

const algos = [LinearWalk, BisectingSearch, StochasticAcceptance]

###############################################################################
# First, I'll use an intuitive test. I tally 1,000 samples over frequencies 
# [5,4,3,2,1]. The tallies should be descending. 
###############################################################################

const freqs = [5,4,3,2,1]
const props = freqs / sum(freqs)

function test_descending(tallies)
    sliding_windows = zip(tallies[1:end-1], tallies[2:end])
    @test all(pair -> pair[1] > pair[2], sliding_windows)
end

for algo in algos
    test_descending(rand_tally(algo(freqs), 1000))
    test_descending(rand_tally(algo(props), 1000))
end

###############################################################################
# Now, I'll test sampling following growth. Remember, to call `normalize!` 
# prior to sampling, following a `push!`. I should add a statistical test
# for distribution comparisons. 
###############################################################################

function test_ascending(tallies)
    sliding_windows = zip(tallies[1:end-1], tallies[2:end])
    @test all(pair -> pair[1] < pair[2], sliding_windows)
end

xs = collect(1:5)

for algo in algos
    selector = algo(xs)
    test_ascending(rand_tally(selector, 1000))
    
    # Cheap test of iterator interface conformity.
    @test collect(selector) == xs
    
    # push! then normalize.
    push!(selector, 1)
    @test length(selector) == 6
    normalize!(selector)
    
    tally = rand_tally(selector, 300000)
    test_ascending(tally[1:5])
    @test tally[6] < tally[2]
end

###############################################################################
# Test the WheelFromDict wrapper.
###############################################################################

d = @compat Dict{Symbol, Int}(:red => 1, :green => 2, :blue => 3)
wheel = WheelFromDict(d)

@test length(wheel) == 3

for (k, v) in wheel
    @test k ∈ keys(d)
    @test v == d[k]
end

sampled_d = rand_dict(wheel, 1000)
@test sampled_d[:red] < sampled_d[:green] < sampled_d[:blue]

wheel[:gold] = 4
normalize!(wheel)
sampled_d = rand_dict(wheel, 1000)
@test sampled_d[:red] < sampled_d[:green] < sampled_d[:blue] < sampled_d[:gold]
