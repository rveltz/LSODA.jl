[![Build Status](https://travis-ci.org/rveltz/LSODA.jl.svg?branch=master)](https://travis-ci.org/rveltz/LSODA.jl)
[![Coverage Status](https://coveralls.io/repos/github/rveltz/LSODA.jl/badge.svg?branch=master)](https://coveralls.io/github/rveltz/LSODA.jl?branch=master)
[![Build status](https://ci.appveyor.com/api/projects/status/p879qachs4c52y4u/branch/master?svg=true)](https://ci.appveyor.com/project/rveltz/lsoda-jl/branch/master)
[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://rveltz.github.io/LSODA.jl/stable)
[![](https://img.shields.io/badge/docs-latest-blue.svg)](https://rveltz.github.io/LSODA.jl/latest)


# LSODA.jl

## Introduction

**LSODA.jl** is a Julia package that interfaces to the [liblsoda](https://github.com/sdwfrost/liblsoda) library, developed by [Simon Frost](http://www.vet.cam.ac.uk/directory/sdf22@cam.ac.uk) ([@sdwfrost](http://github.com/sdwfrost)), thereby providing a way to use the LSODA algorithm from Linda Petzold and Alan Hindmarsh from [Julia](http://julialang.org/). **[Clang.jl](https://github.com/ihnorton/Clang.jl)** has been used to write the library and **[Sundials.jl](https://github.com/JuliaDiffEq/Sundials.jl)** was a inspiring source.

## Installation

To install this package, run the command `add LSODA`.
## Simplified Functions

To solve an ODE, one can call the simplified solver:

```julia
function rhs!(t, x, ydot, data)
	ydot[1]=1.0E4 * x[2] * x[3] - .04E0 * x[1]
	ydot[3]=3.0E7 * x[2] * x[2]
	ydot[2]=-ydot[1] - ydot[3]
  nothing
end

y0 = [1.,0.,0.]
tspan = [0., 0.4]
res =  lsoda(rhs!, y0, tspan, reltol= 1e-4, abstol = Vector([1.e-6,1.e-10,1.e-6]))
```


To reproduce the test example from liblsoda, on can use:

```julia
lsoda_0(rhs!, y0, tspan, reltol= 1e-4, abstol = Vector([1.e-6,1.e-10,1.e-6]))
```

This should give the following.

```
at t =   4.0000e-01 y=   9.851712e-01   3.386380e-05   1.479493e-02
at t =   4.0000e+00 y=   9.055333e-01   2.240655e-05   9.444430e-02
at t =   4.0000e+01 y=   7.158403e-01   9.186334e-06   2.841505e-01
at t =   4.0000e+02 y=   4.505250e-01   3.222964e-06   5.494717e-01
at t =   4.0000e+03 y=   1.831976e-01   8.941774e-07   8.168016e-01
at t =   4.0000e+04 y=   3.898729e-02   1.621940e-07   9.610125e-01
at t =   4.0000e+05 y=   4.936362e-03   1.984221e-08   9.950636e-01
at t =   4.0000e+06 y=   5.161832e-04   2.065786e-09   9.994838e-01
at t =   4.0000e+07 y=   5.179811e-05   2.072030e-10   9.999482e-01
at t =   4.0000e+08 y=   5.283524e-06   2.113420e-11   9.999947e-01
at t =   4.0000e+09 y=   4.658945e-07   1.863579e-12   9.999995e-01
at t =   4.0000e+10 y=   1.423392e-08   5.693574e-14   1.000000e+00
```

## JuliaDiffEq Common Interface

The functionality of LSODA.jl can be accessed through the JuliaDiffEq common interface. To do this, you build a problem object for like:

```julia
using DiffEqBase
function rhs!(t, x, ydot, data)
    ydot[1]=1.0E4 * x[2] * x[3] - .04E0 * x[1]
    ydot[3]=3.0E7 * x[2] * x[2]
    ydot[2]=-ydot[1] - ydot[3]
  nothing
end

y0 = [1.,0.,0.]
tspan = (0., 0.4)
prob = ODEProblem(rhs!,y0,tspan)
```

This problem is solved by LSODA by using the lsoda() algorithm in the common `solve` command as follows:

```julia
sol = solve(prob,lsoda())
```

Many keyword arguments can be used to control the solver, its tolerances, and its output formats. For more information, please see the [DifferentialEquations.jl documentation](https://juliadiffeq.github.io/DiffEqDocs.jl/latest/).
