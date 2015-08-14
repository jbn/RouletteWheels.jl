module RouletteWheels

using Compat

import Base.done
import Base.eltype
import Base.getindex
import Base.length
import Base.next
import Base.push!
import Base.rand
import Base.setindex!
import Base.start

export RouletteWheel, LinearWalk, BisectingSearch, StochasticAcceptance
export rand_tally, normalize!, WheelFromDict

abstract RouletteWheel

start(sampler::RouletteWheel) = start(sampler.freqs)
next(sampler::RouletteWheel, i) = next(sampler.freqs, i)
done(sampler::RouletteWheel, i) = done(sampler.freqs, i)
length(sampler::RouletteWheel) = length(sampler.freqs)
eltype(sampler::RouletteWheel) = eltype(sampler.freqs)

getindex(sampler::RouletteWheel, i) = sampler.freqs[i]

rand(sampler::RouletteWheel, n) = [rand(sampler) for i in 1:n]

function push!(sampler::RouletteWheel, x)
    push!(sampler.freqs, 0)
    @inbounds sampler[length(sampler)] = x
end

function rand_tally(sampler::RouletteWheel, n) 
    tallies = zeros(Int, length(sampler))
    for i in 1:n
        @inbounds tallies[rand(sampler)] += 1
    end
    tallies
end

normalize!(sampler::RouletteWheel) = sampler


##############################################################################
# Asymptotics:
# - Sampling:    O(n)
# - Normalizing: O(0)
##############################################################################
type LinearWalk{T <: Real} <: RouletteWheel
    freqs::Vector{T}
    total::T
end

LinearWalk(freqs) = LinearWalk(
    collect(freqs),
    sum(freqs)
)

function setindex!(sampler::LinearWalk, x, i)
    sampler.total += (x - sampler.freqs[i])
    sampler.freqs[i] = x
end

function rand(sampler::LinearWalk)
    accum = 0.0
    terminal_cdf_point = rand() * sampler.total
    for i = 1:length(sampler)
        @inbounds accum += sampler.freqs[i]
        if accum > terminal_cdf_point
            return i
        end
    end
end

type BisectingSearch{T <: Real} <: RouletteWheel
    freqs::Vector{T}
    total::T
    cdf::Vector{Float64}
end

##############################################################################
# Asymptotics:
# - Sampling:    O(log n)
# - Normalizing: O(n)
##############################################################################
function BisectingSearch(freqs)
    total = sum(freqs)
    cdf = zeros(Float64, length(freqs))
    sampler = BisectingSearch(collect(freqs), total, cdf)
    normalize!(sampler)
end

function setindex!(sampler::BisectingSearch, x, i)
    sampler.total += (x - sampler.freqs[i])
    sampler.freqs[i] = x
end

function push!(sampler::BisectingSearch, x)
    push!(sampler.freqs, 0)
    push!(sampler.cdf, 0)
    sampler[length(sampler)] = x 
end

function normalize!(sampler::BisectingSearch)
    accum = 0.0
    for (i, freq) in enumerate(sampler.freqs)
        accum += freq / sampler.total
        @inbounds sampler.cdf[i] = accum
    end
    sampler
end

rand(sampler::BisectingSearch) = searchsortedfirst(sampler.cdf, rand())


##############################################################################
# Asymptotics:
# - Sampling:    O(1)
# - Normalizing: O(0)
#
# See:
#    Lipowski, Adam, and Dorota Lipowska. "Roulette-wheel selection via 
#    stochastic acceptance." Physica A: Statistical Mechanics and its 
#    Applications 391, no. 6 (2012): 2193-2196.
#
#    http://www.sciencedirect.com/science/article/pii/S0378437111009010
##############################################################################
type StochasticAcceptance{T <: Real} <: RouletteWheel
    freqs::Vector{T}
    max_value::T
end

StochasticAcceptance(freqs) = StochasticAcceptance(
    collect(freqs),
    maximum(freqs)
)

function setindex!(sampler::StochasticAcceptance, x, i)
    last_x = sampler.freqs[i]
        
    if x > sampler.max_value
        max_value = x
    elseif last_x == sampler.max_value && x < last_x
        sampler.max_value = maximum(sampler.freqs)
    end
            
    sampler.freqs[i] = x
end

function rand(sampler::StochasticAcceptance)
    idxs = 1:length(sampler)
    while true
        i = rand(idxs)
        @inbounds if rand() < sampler.freqs[i] / sampler.max_value
            return i
        end
    end
end

##############################################################################
# TODO: XXX: Clean up the following code.
# It lets the user wrap a dictionary. The keys are what you want to sample. 
# The values are the frequencies.
##############################################################################

type WheelFromDict
    wheel
    key_vector
    mapping
    
    function WheelFromDict(d, wheel_algo)
        ks = @compat Vector{eltype(keys(d))}()
        freqs = @compat Vector{eltype(values(d))}()
        mapping = copy(d)
        for (k, v) = d
            push!(ks, k)
            push!(freqs, v)
        end
        
        new(wheel_algo(freqs), ks, mapping)
    end
end

rand(wheel::WheelFromDict) = wheel.key_vector[rand(wheel.wheel)]

end 
