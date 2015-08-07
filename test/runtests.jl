using RouletteWheels
using Base.Test

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
# prior to sampling, following a `push!`. 
###############################################################################

xs = collect(1:4)
expected_xs = round(xs / sum(xs) * 100)
ys = [xs..., 1]
expected_ys = round(ys / sum(ys) * 100)

for algo in algos
    selector = algo(xs)
    res_xs = rand_tally(selector, 300000)
    res_xs = round(res_xs / sum(res_xs) * 100)
    @test round(res_xs) == expected_xs
    
    # Cheap test of iterator interface conformity.
    @test collect(selector) == xs
    
    # push! then normalize.
    push!(selector, 1)
    @test length(selector) == 5
    normalize!(selector)
    
    res_ys = rand_tally(selector, 300000)
    res_ys = round(res_ys / sum(res_ys) * 100)
    @test round(res_ys) == expected_ys
end
