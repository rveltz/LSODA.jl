using LSODA
using Test

# write your own tests here
println("--> test1 =============")
include("test1.jl")
println("\n--> test2 =============")
include("test2.jl")
println("\n--> test common =============")
include("test_common.jl")
