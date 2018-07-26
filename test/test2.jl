using LSODA

function rhs!(t, x, ydot, data)
	ydot[1]=1.0E4 * x[2] * x[3] - .04E0 * x[1]
	ydot[3]=3.0E7 * x[2] * x[2]
	ydot[2]=-ydot[1] - ydot[3]
  nothing
end

y0 = [1.,0.,0.]
println("\n####################################\n--> Use of a old wrapper for speed comparison")
tspan = [0., 0.4]
@time LSODA.lsoda_0(rhs!, y0, tspan, reltol= 1e-4,abstol = Vector([1.e-6,1.e-10,1.e-6]))
@time LSODA.lsoda_0(rhs!, y0, tspan, reltol= 1e-4,abstol = Vector([1.e-6,1.e-10,1.e-6]))

# case with a vector
println("\n####################################\n--> Use of a vector of times where output is required")
tspan = [4 .* 10.0^k for k=-1:10]
res = LSODA.lsoda(rhs!, y0, tspan, reltol= 1e-4,abstol = Vector([1.e-6,1.e-10,1.e-6]))
res = @time LSODA.lsoda(rhs!, y0, tspan, reltol= 1e-4,abstol = Vector([1.e-6,1.e-10,1.e-6]))
println(res)

# #case where we don't have to declare a new context
println("\n####################################\n--> Use of a lsoda_evolve!")
# y0 = [1.,0.,0.]
# tspan = [4.*10.0^k for k=-1:10]
# ctx, _ = LSODA.lsoda(rhs!, y0, tspan[1:2], reltol= 1e-4,abstol = Vector([1.e-6,1.e-10,1.e-6]))
# @time for k=2:length(tspan)
# 	LSODA.lsoda_evolve!(ctx,y0,tspan[k-1:k])
# 	@printf("at t = %12.4e y= %14.6e %14.6e %14.6e\n",tspan[k],y0[1], y0[2], y0[3])
# end
# lsoda_free(ctx)
