RouletteWheels.jl
===

[![Build Status](https://travis-ci.org/JuliaStats/Distributions.jl.svg?branch=master)](https://travis-ci.org/JuliaStats/Distributions.jl)
[![Distributions](http://pkg.julialang.org/badges/Distributions_release.svg)](http://pkg.julialang.org/?pkg=Distributions&ver=release)

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

Finally,  you can collect a set random tally for each index over n tallies.

```julia
rand_tally(wheel, 100) 
```

`BisectingSearch` has low jitter, making it suitable for real-time operations. 
And, it is fast, *assuming few mutations on the frequencies.* 
`StochasticAcceptance` tends to perform the best, given frequent mutation. 
See: [Fast Proportional Selection Algorithms](http://jbn.github.io/fast_proportional_selection/) for a discussion. 

## Warning

I'm a seasoned programmer. But, I started learning Julia in late-July, 2015. 
Take this package with a grain of salt. 

## Todo

- Add `auto_tune` function. It should return a RouletteWheel that is optimal 
given a specific usage pattern. 
