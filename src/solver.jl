function lsodafun{T1,T2,T3}(t::T1,y::T2,yp::T3,userfun::UserFunctionAndData)
  # println("Cas 1,userfun = ")
  # println(userfun.func)
  y_ = pointer_to_array(y,userfun.neq)
  ydot_ = pointer_to_array(yp,userfun.neq)
  userfun.func(t, y_, ydot_,userfun.data)
  return Int32(0)
end

function lsodafun{T1,T2,T3}(t::T1,y::T2,yp::T3, userfun::Function)
    # y_ = unsafe_wrap(Array,y,3,false)
    # ydot_ = unsafe_wrap(Array,yp,3,false)#pointer_to_array(yp,3)
    # println("y=",unsafe_wrap(Array,y,2,false),"\n")
    y_ = pointer_to_array(y,3)
    ydot_ = pointer_to_array(yp,3)
    userfun(t, y_, ydot_)
    return Int32(0)
end

function lsoda_0(f::Function, y0::Vector{Float64}, tspan::Vector{Float64}; userdata::Any=nothing, reltol::Union{Float64,Vector}=1e-4, abstol::Union{Float64,Vector}=1e-10)
  neq = Int32(length(y0))
  userfun = UserFunctionAndData(f, userdata,neq)
  # println("-->userfun = ",userfun,typeof(userfun))

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
  for i=1:neq
    y[i] = y0[i]
  end

  t[1] = tspan[1]
  tout[1] = tspan[2]
  #
  opt = lsoda_opt_t()
    opt.ixpr = 0
    opt.rtol = pointer(rtol)
    opt.atol = pointer(atol)
    opt.itask = 1
  #

  const fex_c = cfunction(lsodafun,Cint,(Cdouble,Ptr{Cdouble},Ptr{Cdouble},Ref{typeof(userfun)}))

  ctx = lsoda_context_t()
    ctx.function_ = fex_c
    ctx.neq = neq
    ctx.state = 1
    ctx.data = pointer_from_objref(userfun)

  lsoda_prepare(ctx,opt)
  for i=1:12
    lsoda(ctx,y,t,tout[1])
    @printf("at t = %12.4e y= %14.6e %14.6e %14.6e\n",t[1],y[1], y[2], y[3])
    tout[1] *= 10.0E0
  end
  return ctx
end

function lsoda(f::Function, y0::Vector{Float64}, tspan::Vector{Float64}; userdata::Any=nothing, reltol::Union{Float64,Vector}=1e-4, abstol::Union{Float64,Vector}=1e-10)
  neq = Int32(length(y0))
  userfun = UserFunctionAndData(f, userdata,neq)
  # println("-->userfun = ",userfun,typeof(userfun))

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

  t = Array{Float64}(1)
  tout = Array{Float64}(1)
  y = Array{Float64}(neq)
  for i=1:neq
    y[i] = y0[i]
  end

  t[1] = tspan[1]
  tout[1] = tspan[2]
  #
  opt = lsoda_opt_t()
    opt.ixpr = 0
    opt.rtol = pointer(rtol)
    opt.atol = pointer(atol)
    opt.itask = 1
  #

  const fex_c = cfunction(lsodafun,Cint,(Cdouble,Ptr{Cdouble},Ptr{Cdouble},Ref{typeof(userfun)}))

  ctx = lsoda_context_t()
    ctx.function_ = fex_c
    ctx.neq = neq
    ctx.state = 1
    ctx.data = pointer_from_objref(userfun)

  lsoda_prepare(ctx,opt)
  for i=1:12
    lsoda(ctx,y,t,tout[1])
    @printf("at t = %12.4e y= %14.6e %14.6e %14.6e\n",t[1],y[1], y[2], y[3])
    tout[1] *= 10.0E0
  end
  return ctx
end