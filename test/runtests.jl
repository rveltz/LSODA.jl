# push!(LOAD_PATH, "/Users/rveltz/work/prog_gd/julia")
using LSODA
using Base.Test

# write your own tests here
println("--> test1 =============")
include("test1.jl")
println("\n--> test2 =============")
include("test2.jl")
println("\n--> test common =============")
include("test_common.jl")
