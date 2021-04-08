__precompile__()

module LSODA

using Compat, DiffEqBase
import DiffEqBase: solve
using LinearAlgebra, Printf
using LSODA_jll

const warnkeywords =
    (:save_idxs, :d_discontinuities, :isoutofdomain, :unstable_check,
     :calck, :progress, :timeseries_steps, :dense,
     :dtmin, :dtmax,
     :internalnorm, :gamma, :beta1, :beta2, :qmax, :qmin, :qoldinit)

function __init__()
    global warnlist = Set(warnkeywords)
end

abstract type LSODAAlgorithm <: DiffEqBase.AbstractODEAlgorithm end
abstract type LSODAAlgorithm <: DiffEqBase.AbstractODEAlgorithm end
struct lsoda <: LSODAAlgorithm end

export lsoda, lsoda_0, lsoda_opt_t, lsoda_context_t, lsoda_prepare, lsoda_reset, lsoda_opt_t, lsoda_free, lsoda_evolve!, UserFunctionAndData

export LSODAAlgorithm, solve

include("types_and_consts.jl")
include("handle.jl")
include("solver.jl")
include("common.jl")

end # module
