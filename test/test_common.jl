using LSODA, DiffEqProblemLibrary
prob = prob_ode_linear
sol = solve(prob,LSODAAlg(),save_timeseries=false,saveat=[1/2])
prob = prob_ode_2Dlinear
sol = solve(prob,LSODAAlg(),save_timeseries=false,saveat=[1/2])
