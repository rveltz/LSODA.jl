using LSODA, DiffEqProblemLibrary, Base.Test
prob = prob_ode_linear
sol = solve(prob,LSODAAlg(),saveat=[1/2])
@test sol.t == [0,1/2,1]
prob = prob_ode_2Dlinear
sol = solve(prob,LSODAAlg(),saveat=[1/2])
@test sol.t == [0,1/2,1]
sol = solve(prob,LSODAAlg(),saveat=1/10)
@test sol.t == collect(0:1/10:1)

prob = prob_ode_linear
sol = solve(prob,LSODAAlg())
sol = solve(prob,LSODAAlg(),save_everystep=true,saveat=[1/2])
@test 1/2 ∈ sol.t
prob = prob_ode_2Dlinear
sol = solve(prob,LSODAAlg(),save_everystep=true,saveat=[1/2])
@test 1/2 ∈ sol.t
sol = solve(prob,LSODAAlg(),save_everystep=true,saveat=1/2)
@test 1/2 ∈ sol.t
sol = solve(prob,LSODAAlg(),save_everystep=true,saveat=[1/10,1/5,3/10])#,2/5,1/2,3/5,7/10])
@test 1/10 ∈ sol.t
@test 1/5 ∈ sol.t
@test 3/10 ∈ sol.t
sol = solve(prob,LSODAAlg(),save_everystep=true,saveat=1/10)
for i in 2:length(sol.t)
  @test sol.t[i] > sol.t[i-1]
end
for k in 0:1/10:1
  @test k ∈ sol.t
end

sol = solve(prob,LSODAAlg(),save_start=false,saveat=1/10)
sol.t[1] == 0.1
sol.u[1] != prob.u0
