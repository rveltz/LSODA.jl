module LSODA

using Compat, DiffEqBase
import DiffEqBase: solve

abstract LSODAAlgorithm <: AbstractODEAlgorithm
immutable lsoda <: LSODAAlgorithm end

const depsfile = joinpath(dirname(dirname(@__FILE__)),"deps","deps.jl")
if isfile(depsfile)
    include(depsfile)
else
    error("LSODA is not properly installed. Please run Pkg.build(\"LSODA\")")
end

export lsoda, lsoda_0, lsoda_opt_t, lsoda_context_t, lsoda_prepare, lsoda_opt_t, lsoda_free, lsoda_evolve!, UserFunctionAndData

export LSODAAlgorithm, solve

include("types_and_consts.jl")
include("solver.jl")
include("common.jl")

end # module
