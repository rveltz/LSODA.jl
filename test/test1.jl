using LSODA, Printf

function fex(t::T1, y::T2, ydot::T3, data::T4) where {T1, T2, T3, T4}
	x = unsafe_wrap(Array,y,neq)
	xdot = unsafe_wrap(Array,ydot,neq)

	xdot[1]=1.0E4 * x[2] * x[3] - .04E0 * x[1]
	xdot[3]=3.0E7 * x[2] * x[2]
	xdot[2]= -xdot[1] - xdot[3]

	return Int32(0)
end

fex_c = @cfunction(fex,Cint,(Cdouble,Ptr{Cdouble},Ptr{Cdouble},Ptr{Nothing}))

const atol = Array{Float64}(undef,3)
const rtol = Array{Float64}(undef,3)
t = Array{Float64}(undef,1)
tout = Array{Float64}(undef,1)
const y = Array{Float64}(undef,3)

const neq = Int32(3)

y[1] = 1.0E0
  y[2] = 0.0E0
  y[3] = 0.0E0
  t[1] = 0.0E0
  tout[1] = 0.4E0

opt = lsoda_opt_t()
  opt.ixpr = 0
  opt.rtol = pointer(rtol)
  opt.atol = pointer(atol)
  opt.itask = 1

rtol[1] = 1.0E-4
	rtol[2] = 1.0E-4
  rtol[3] = 1.0E-4
	atol[1] = 1.0E-6
	atol[2] = 1.0E-10
	atol[3] = 1.0E-6

ctx = lsoda_context_t()
  ctx.function_ = fex_c
  ctx.neq = neq
  ctx.state = 1

lsoda_prepare(ctx,opt)

@time for i=1:12
  lsoda(ctx,y,t,tout[1])
  Printf.@printf("at t = %12.4e y= %14.6e %14.6e %14.6e\n",t[1],y[1], y[2], y[3])
  if (ctx.state <= 0)
			error("error istate = ", ctx.state)
	end
	tout[1] *= 10.0E0
end
println("Done!")
lsoda_free(ctx)
