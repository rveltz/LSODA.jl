using LSODA, ODEProblemLibrary, Test
import ODEProblemLibrary: prob_ode_linear, prob_ode_2Dlinear
using SciMLBase: ReturnCode

prob = prob_ode_linear
sol = solve(prob,lsoda(),saveat=[1/2])
@test sol.t == [1/2,1]
prob = prob_ode_2Dlinear
sol = solve(prob,lsoda(),saveat=[1/2])
@test sol.t == [1/2,1]
sol = solve(prob,lsoda(),saveat=1/10)
@test sol.t == collect(0:1/10:1)

prob = prob_ode_linear
sol = solve(prob,lsoda())
sol_maxiters = solve(prob, lsoda(), maxiters = 1, save_everystep = false)
@test sol_maxiters.retcode == ReturnCode.MaxIters
@test sol_maxiters.t[end] < prob.tspan[end]
sol = solve(prob,lsoda(),save_everystep=true,saveat=[1/2])
@test 1/2 ∈ sol.t
prob = prob_ode_2Dlinear
sol = solve(prob,lsoda(),save_everystep=true,saveat=[1/2])
@test 1/2 ∈ sol.t
sol = solve(prob,lsoda(),save_everystep=true,saveat=1/2)
@test 1/2 ∈ sol.t
sol = solve(prob,lsoda(),save_everystep=true,saveat=[1/10,1/5,3/10])#,2/5,1/2,3/5,7/10])
@test 1/10 ∈ sol.t
@test 1/5 ∈ sol.t
@test 3/10 ∈ sol.t
sol = solve(prob,lsoda(),save_everystep=true,saveat=1/10)
for i in 2:length(sol.t)
  @test sol.t[i] > sol.t[i-1]
end
for k in 0:1/10:1
  @test k ∈ sol.t
end

sol = solve(prob,lsoda(),save_start=false,saveat=1/10)
sol.t[1] == 0.1
sol.u[1] != prob.u0

# tstops tests
println("--> tstops tests =============")

# tstops with saveat should not affect save times
prob = prob_ode_linear
sol = solve(prob,lsoda(),saveat=1/10,tstops=[0.5])
@test sol.t == collect(0:1/10:1)

# tstops with save_everystep should include tstop time
sol = solve(prob,lsoda(),save_everystep=true,tstops=[0.5])
@test 0.0 ∈ sol.t
@test 1.0 ∈ sol.t
@test 0.5 ∈ sol.t
for i in 2:length(sol.t)
  @test sol.t[i] > sol.t[i-1]
end

# multiple tstops with saveat
sol = solve(prob,lsoda(),saveat=1/4,tstops=[0.1,0.3,0.7,0.9])
@test sol.t == collect(0:1/4:1)

# 2D problem with tstops
prob = prob_ode_2Dlinear
sol = solve(prob,lsoda(),saveat=[1/2],tstops=[0.25,0.75])
@test sol.t == [1/2,1]

# tstops at boundaries should be filtered out
prob = prob_ode_linear
sol = solve(prob,lsoda(),saveat=1/4,tstops=[0.0,0.5,1.0])
@test sol.t == collect(0:1/4:1)

# tstops with save_everystep and saveat
sol = solve(prob,lsoda(),save_everystep=true,saveat=[1/2],tstops=[0.3])
@test 1/2 ∈ sol.t
@test 0.3 ∈ sol.t

# tstops improves accuracy at discontinuities
using DiffEqBase
function f_disc!(du,u,p,t)
    du[1] = t < 0.5 ? 1.0 : 2.0
end
prob_disc = ODEProblem(f_disc!,[0.0],(0.0,1.0))
sol_stop = solve(prob_disc,lsoda(),saveat=0.25,tstops=[0.5])
exact = [0.0, 0.25, 0.5, 1.0, 1.5]
for i in 1:length(exact)
    @test isapprox(sol_stop.u[i][1],exact[i],atol=1e-4)
end
