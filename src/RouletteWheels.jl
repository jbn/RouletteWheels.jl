module RouletteWheels

export RouletteWheel, LinearWalk, BisectingSearch, StochasticAcceptance
export rand_tally, normalize!

import Base.done
import Base.length
import Base.next
import Base.push!
import Base.rand
import Base.start

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
    sampler[length(sampler)] = x
end

function rand_tally(sampler::RouletteWheel, n) 
    tallies = zeros(Int, length(sampler))
    for i in 1:n
        tallies[rand(sampler)] += 1
    end
    tallies
end

normalize!(sampler::RouletteWheel) = sampler

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
        accum += sampler.freqs[i]
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
    # How can I call the lower-specificity method?
    push!(sampler.freqs, 0)
    push!(sampler.cdf, 0)
    sampler[length(sampler)] = x
end

function normalize!(sampler::BisectingSearch)
    accum = 0.0
    for (i, freq) in enumerate(sampler.freqs)
        accum += freq / sampler.total
        sampler.cdf[i] = accum
    end
    sampler
end

rand(sampler::BisectingSearch) = searchsortedfirst(sampler.cdf, rand())

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
        if rand() < sampler.freqs[i] / sampler.max_value
            return i
        end
    end
end

end 
