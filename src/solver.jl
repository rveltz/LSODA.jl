function lsodafun{T1,T2,T3}(t::T1,y::T2,yp::T3,userfun::UserFunctionAndData)
  y_ = unsafe_wrap(Array,y,userfun.neq)
  ydot_ = unsafe_wrap(Array,yp,userfun.neq)
  userfun.func(t, y_, ydot_,userfun.data)
  return Int32(0)
end

const fex_c = cfunction(lsodafun,Cint,(Cdouble,Ptr{Cdouble},Ptr{Cdouble},Ref{UserFunctionAndData}))

function lsoda_0(f::Function, y0::Vector{Float64}, tspan::Vector{Float64}; userdata::Any=nothing, reltol::Union{Float64,Vector}=1e-4, abstol::Union{Float64,Vector}=1e-10)
  neq = Int32(length(y0))
  userfun = UserFunctionAndData(f, userdata,neq)

  atol = ones(Float64,neq)
  rtol = ones(Float64,neq)

  if typeof(abstol) == Float64
    atol *= abstol
  else
    atol = copy(abstol)
  end

  if typeof(reltol) == Float64
    rtol *= reltol
  else
    rtol = copy(reltol)
  end

  t = Array{Float64}(1)
  tout = Array{Float64}(1)
  y = Array{Float64}(neq)
  y = copy(y0)

  t[1] = tspan[1]
  tout[1] = tspan[2]
  #
  opt = lsoda_opt_t()
    opt.ixpr = 0
    opt.rtol = pointer(rtol)
    opt.atol = pointer(atol)
    opt.itask = 1
  #

  ctx = lsoda_context_t()
    ctx.function_ = fex_c
    ctx.neq = neq
    ctx.state = 1
    ctx.data = pointer_from_objref(userfun)

  lsoda_prepare(ctx,opt)
  for i=1:12
    lsoda(ctx,y,t,tout[1])
	@assert (ctx.state >0) string("LSODA error istate = ", ctx.state)
    @printf("at t = %12.4e y= %14.6e %14.6e %14.6e\n",t[1],y[1], y[2], y[3])
    tout[1] *= 10.0E0
  end
  return ctx
end

"""
  lsoda(f::Function, y0::Vector{Float64}, tspan::Vector{Float64}; userdata::Any=nothing, reltol::Union{Float64,Vector}=1e-4, abstol::Union{Float64,Vector}=1e-10)

Solves a set of ordinary differential equations using the LSODA algorithm. The vector field encoded in an inplace f::Function needs to have the self-explanatory arguments f(t, y, ydot, data)
"""
function lsoda(f::Function, y0::Vector{Float64}, tspan::Vector{Float64}; userdata::Any=nothing, reltol::Union{Float64,Vector}=1e-4, abstol::Union{Float64,Vector}=1e-10)
  neq = Int32(length(y0))
  userfun = UserFunctionAndData(f, userdata,neq)

  atol = ones(Float64,neq)
  rtol = ones(Float64,neq)

  yres = zeros(length(tspan), length(y0))

  if typeof(abstol) == Float64
    atol *= abstol
  else
    atol = copy(abstol)
  end

  if typeof(reltol) == Float64
    rtol *= reltol
  else
    rtol = copy(reltol)
  end

  t    = Array{Float64}(1)
  tout = Array{Float64}(1)
  y    = Array{Float64}(neq)
  y    = copy(y0)

  t[1]    = tspan[1]
  tout[1] = tspan[2]

  opt = lsoda_opt_t()
    opt.ixpr = 0
    opt.rtol = pointer(rtol)
    opt.atol = pointer(atol)
    opt.itask = 1

  ctx = lsoda_context_t()
    ctx.function_ = fex_c
    ctx.neq = neq
    ctx.state = 1
    ctx.data = pointer_from_objref(userfun)

  lsoda_prepare(ctx,opt)
  yres[1,:] = y0

  for k in 2:length(tspan)
	tout[1] = tspan[k]
    lsoda(ctx,y,t,tout[1])
	@assert (ctx.state >0) string("LSODA error istate = ", ctx.state)
	yres[k,:] = copy(y)
  end
  return ctx, yres
end

"""
  lsoda_evolve!(ctx::lsoda_context_t,y::Vector{Float64},tspan::Vector{Float64};data=nothing)

Solves a set of ordinary differential equations using the LSODA algorithm and the context variable ctx. This avoid re-allocating ctx. You have to be carefull to remember the current time of this function will return an error.

"""
function lsoda_evolve!(ctx::lsoda_context_t,y::Vector{Float64},tspan::Vector{Float64};data=nothing)
	if data != nothing
		ctx.data.userdata = data
	end
	@assert ctx.neq == length(y)
	t    = Array{Float64}(1)
	tout = Array{Float64}(1)
	t[1] = tspan[1]
	tout[1] = tspan[2]
	lsoda(ctx,y,t,tout[1])
	@assert (ctx.state >0) string("LSODA error istate = ", ctx.state)
end
