RouletteWheels.jl
===

[![Build Status](https://travis-ci.org/jbn/RouletteWheels.jl.svg?branch=master)](https://travis-ci.org/jbn/RouletteWheels.jl)
[![RouletteWheels](http://pkg.julialang.org/badges/RouletteWheels_0.3.svg)](http://pkg.julialang.org/?pkg=RouletteWheels&ver=release)
[![RouletteWheels](http://pkg.julialang.org/badges/RouletteWheels_0.4.svg)](http://pkg.julialang.org/?pkg=RouletteWheels&ver=nightly)
[![Coverage Status](https://coveralls.io/repos/jbn/RouletteWheels.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/jbn/RouletteWheels.jl?branch=master)
[![Build status](https://ci.appveyor.com/api/projects/status/097d6yxplrk8etp7?svg=true)](https://ci.appveyor.com/project/jbn/roulettewheels-jl)

A Julia package for [fitness proportionate selection](https://en.wikipedia.org/wiki/Fitness_proportionate_selection), or Roulette Wheels. 

Installation
---

```julia
Pkg.add("RouletteWheels")
```

Usage
---

The root type for all the algorithms is `RouletteWheel`. Each algorithm is a 
subtype of this abstract type. There are three algorithms: `LinearWalk`, 
`BisectingSearch`, and `StochasticAcceptance`. The constructor takes a single 
iterable of frequencies or proportions. 

```julia
using RouletteWheels

wheel = StochasticAcceptance(1:10)
```

You can modify the frequency or proportion of any index just like you would any 
array.

```julia
wheel[5] = 100
@assert wheel[5] == 100
```

You can also grow the wheel, adding a new index to sample.

```julia
push!(wheel, 1)
```

The simplest way to proportionally sample an index is with the rand function 
(h/t [Distributions.jl](https://github.com/JuliaStats/Distributions.jl)). 
**However, if you used `push!`, you must call `normalize!` first.**

```julia
normalize!(wheel)  # Only if you push!ed.
rand(wheel)
```

You can also collect a sample of size n.

```julia
rand(wheel, 10)
```

You can also collect a set random tally for each index over n tallies.

```julia
rand_tally(wheel, 100) 
```

Often, you want to sample a key rather than an index. The `WheelFromDict` 
wrapper makes this convenient. The constructor takes and copies a dictionary 
mapping key to frequency. It optionally takes the algorithm to use for the 
underlying roulette wheel. 

This wrapper does not implement `push!`. Instead, you set in index just as you 
would for a `Dict`. You must still call normalize after finishing all 
modifications. 

```julia
wheel = WheelFromDict(
    @compat Dict{Symbol, Int}(:red => 1, :green => 2, :blue => 3)
)
rand(wheel) #=> :green
```

You can also collect a dictionary built from repeated samples. The values are the sampled frequencies.

```julia
rand_dict(wheel, 100)
``` 

Asymptotics
---
| Algorithm | Sampling | Normalizing |
| :---: | ---: | ---: |
| `LinearSearch`         |  O(n)   | O(0)    |
| `BisectingSearch`      |  O(log n)   | O(n)    |
| `StochasticAcceptance` |  O(1)   | O(0)    |

`BisectingSearch` has low jitter, making it suitable for real-time operations. 
And, it is fast, *assuming few mutations on the frequencies.* 
`StochasticAcceptance` tends to perform the best, given frequent mutation. 
See: [Fast Proportional Selection Algorithms](http://jbn.github.io/fast_proportional_selection/) for a discussion. 

Asymptotics and real-world performance are often quiet different. For example, 
`LinearSearch` is very fast for small `n`. It's striding memory consecutively. 
Therefore, it is often useful to estimate the fastest algorithm. To do so , 
use `select_fastest`. It takes a function to simulate your expected usage 
patterns and an initial set of frequencies. But, take the estimates with a 
grain of salt. The function only uses `tic` and `toq`.

```julia
fastest, all_timings = select_fastest(1:10) do wheel
    for _ in 1:100000
        rand(wheel)
    end
end
fastest # => LinearWalk 
```

## Warning

I'm a seasoned programmer. But, I started learning Julia in late-July, 2015. 
Take this package with a grain of salt. 

## Todo

- Fix `eltype` definitions. They are wrong.
