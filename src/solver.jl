function lsodafun(t::T1, y::T2, yp::T3, userfun::UserFunctionAndData) where {T1, T2, T3}
  y_ = unsafe_wrap(Array,y,userfun.neq)
  ydot_ = unsafe_wrap(Array,yp,userfun.neq)
  userfun.func(t, y_, ydot_,userfun.data)
  return Int32(0)
end

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

  t = Float64[tspan[1]]
  tout = Float64[tspan[2]]
  y = copy(y0)

  #
  opt = lsoda_opt_t()
    opt.ixpr = 0
    opt.rtol = pointer(rtol)
    opt.atol = pointer(atol)
    opt.itask = 1
  #

  ctx = lsoda_context_t()
    ctx.function_ = @cfunction($lsodafun,Cint,(Cdouble,Ptr{Cdouble},Ptr{Cdouble},Ref{UserFunctionAndData})).ptr
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
end

"""
  lsoda(f::Function, y0::Vector{Float64}, tspan::Vector{Float64}; userdata::Any=nothing, reltol::Union{Float64,Vector}=1e-4, abstol::Union{Float64,Vector}=1e-10)

Solves a set of ordinary differential equations using the LSODA algorithm. The vector field encoded in an inplace f::Function needs to have the self-explanatory arguments f(t, y, ydot, data)
"""
function lsoda(f::Function, y0::Vector{Float64}, tspan::Vector{Float64}; userdata::Any=nothing, reltol::Union{Float64,Vector}=1e-4, abstol::Union{Float64,Vector}=1e-10,nbsteps = 10000)
  neq = Int32(length(y0))
  userfun = UserFunctionAndData(f, userdata, neq)

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

  t    = Float64[tspan[1]]
  tout = Float64[tspan[2]]
  y    = copy(y0)

  opt = lsoda_opt_t()
    opt.mxstep = nbsteps
    opt.ixpr = 0
    opt.rtol = pointer(rtol)
    opt.atol = pointer(atol)
    opt.itask = 1

  ctx_ptr = lsoda_context_t()
    ctx_ptr.function_ = @cfunction($lsodafun,Cint,(Cdouble,Ptr{Cdouble},Ptr{Cdouble},Ref{UserFunctionAndData})).ptr
    ctx_ptr.neq = neq
    ctx_ptr.state = 1
    ctx_ptr.data = pointer_from_objref(userfun)

  lsoda_prepare(ctx_ptr,opt)
  yres[1,:] = y0

  for k in 2:length(tspan)
		tout[1] = tspan[k]
	  lsoda(ctx_ptr,y,t,tout[1])
		@assert (ctx_ptr.state >0) string("LSODA error istate = ", ctx_ptr.state, ", error = ",unsafe_string(ctx_ptr.error))
		yres[k,:] = copy(y)
  end

  lsoda_free(ctx_ptr)
  return yres
end

"""
  lsoda_evolve!(ctx::lsoda_context_t,y::Vector{Float64},tspan::Vector{Float64})

Solves a set of ordinary differential equations using the LSODA algorithm and the context variable ctx. This avoid re-allocating ctx. You have to be carefull to remember the current time or this function will return an error.
"""
function lsoda_evolve!(ctx::lsoda_context_t,y::Vector{Float64},tspan::Vector{Float64})
	@assert ctx.neq == length(y)
# if userdata != nothing
# 		# this functionality is not working yet
# 		# ctx.data.data = userdata
# 		# unsafe_pointer_to_objref(ctx.data).data = userdata
# 	end

	t    = Float64[tspan[1]]
	tout = Float64[tspan[2]]
	lsoda(ctx,y,t,tout[1])
	@assert (ctx.state >0) string("LSODA error istate = ", ctx.state)
end
