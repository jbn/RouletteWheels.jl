using RouletteWheels
using FactCheck
using Distributions
using Compat

const algos = [LinearWalk, BisectingSearch, StochasticAcceptance]

function in_ci(wheel, n)
    ps = collect(wheel)
    ps /= sum(ps)
    tallies = rand_tally(wheel, n)
    
    for (p, tally) in zip(ps, tallies)
        (l_b, u_b) = quantile(Binomial(n, p), [0.00001, 0.99999])
        if u_b < tally < l_b
            return false
        end
    end
    
    return true
end


facts("A RouletteWheel") do 
    context("iterates over the underlying frequency") do 
        for algo in algos
            @fact collect(algo([1,9,9,4])) --> [1, 9, 9, 4]
        end
    end

    context("samples in proportion to the given frequency") do 
        freqs = [5,4,9,2,4]
        for algo in algos
            @fact in_ci(algo(freqs), 10000) --> true
        end
    end

    context("samples in proportion to the given proportion") do 
        ps = [5,4,9,2,4]
        ps /= sum(ps)
        for algo in algos
            @fact in_ci(algo(ps), 10000) --> true
        end
    end
    
    context("allows for push! given a normalize!") do 
        freqs = [5,4,9,2,4]
        for algo in algos
            wheel = algo(freqs)

            push!(wheel, 1)
            @fact length(wheel) --> 6
            normalize!(wheel)
            @fact wheel[6] --> 1

            @fact in_ci(wheel, 10000) --> true
        end
    end
end

facts("The WheelFromDict wrapper") do 
    context("samples underlying values instead of an index") do 
        d = @compat Dict{Symbol, Int}(:red => 1, :green => 5, :blue => 20)
        wheel = WheelFromDict(d)
        @fact length(wheel) --> 3

        for (k, v) in wheel
            @fact k ∈ keys(d) --> true
            @fact v --> d[k]
        end

        sampled_d = rand_dict(wheel, 10000)
        @fact sampled_d[:red] < sampled_d[:green] < sampled_d[:blue] --> true

        wheel[:gold] = 90
        normalize!(wheel)
        sampled_d = rand_dict(wheel, 10000)
        @fact sampled_d[:red] < sampled_d[:green] < sampled_d[:blue] --> true
        @fact sampled_d[:blue] < sampled_d[:gold] --> true
    end
end

facts("The select_fastest function") do 
    context("selects the fastest wheel over some proportions") do 
        fastest, all_timings = select_fastest(1:3) do wheel
            for _ in 1:1000
                rand(wheel)
            end
        end
        @fact length(all_timings) --> 3
        @fact all_timings[fastest] --> minimum(values(all_timings))
    end
end