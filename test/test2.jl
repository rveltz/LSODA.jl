function rhs!(t, x, ydot, data)
	ydot[1]=1.0E4 * x[2] * x[3] - .04E0 * x[1]
	ydot[3]=3.0E7 * x[2] * x[2]
	ydot[2]=-ydot[1] - ydot[3]
  nothing
end

# rhs!(t, x, ydot) =  rhs!(t, x, ydot, nothing)

y0 = [1.,0.,0.]
tspan = [0., 0.4]
@time lsoda_0(rhs!, y0, tspan, reltol= 1e-4,abstol = Vector([1.e-6,1.e-10,1.e-6]))
@time lsoda_0(rhs!, y0, tspan, reltol= 1e-4,abstol = Vector([1.e-6,1.e-10,1.e-6]))

tspan = [4.*10.0^k for k=-1:10]
_, res = lsoda(rhs!, y0, tspan, reltol= 1e-4,abstol = Vector([1.e-6,1.e-10,1.e-6]))
println(res)