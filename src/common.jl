@noinline function old_cfunction(f, r, a)
  ccall(:jl_function_ptr, Ptr{Cvoid}, (Any, Any, Any), f, r, a)
end

## Common Interface Solve Functions

mutable struct CommonFunction{F,P}
    func::F
    p::P
    neq::Cint
end

function commonfun(t::T1,y::T2,yp::T3,comfun::CommonFunction) where {T1,T2,T3}
  y_ = unsafe_wrap(Array,y,comfun.neq)
  ydot_ = unsafe_wrap(Array,yp,comfun.neq)
  comfun.func(ydot_,y_,comfun.p,t)
  return Int32(0)
end

function solve(
    prob::DiffEqBase.AbstractODEProblem{uType,tupType,isinplace},
    alg::LSODAAlgorithm,
    timeseries=[],ts=[],ks=[];

    verbose=true,
    abstol=1/10^6,reltol=1/10^3,
    tstops=Float64[],
    saveat=Float64[], maxiter=Int(1e5),
    callback=nothing,
    timeseries_errors=true,
    save_everystep=isempty(saveat),
    save_start = save_everystep || isempty(saveat) || typeof(saveat) <: Number ? true : prob.tspan[1] in saveat,
    userdata=nothing,
    alias_u0=false,
    kwargs...) where {uType,tupType,isinplace}

    tType = eltype(tupType)

    if verbose
        warned = !isempty(kwargs) && check_keywords(alg, kwargs, warnlist)
        if !(typeof(prob.f) <: DiffEqBase.AbstractParameterizedFunction)
            if DiffEqBase.has_tgrad(prob.f)
                @warn("Explicit t-gradient given to this stiff solver is ignored.")
                warned = true
            end
            if DiffEqBase.has_jac(prob.f)
                @warn("Explicit Jacobian given to this stiff solver is ignored.")
                warned = true
            end
        end
        warned && warn_compat()
    end

    if prob.f.mass_matrix != I
        error("This solver is not able to use mass matrices.")
    end

    if callback != nothing || prob.callback != nothing
        error("LSODA is not compatible with callbacks.")
    end

    tspan = prob.tspan
    t0 = tspan[1]
    T = tspan[end]

    if typeof(saveat) <: Number
        if (tspan[1]:saveat:tspan[end])[end] == tspan[end]
          saveat_vec = convert(Vector{tType},collect(tType,tspan[1]+saveat:saveat:tspan[end]))
        else
          saveat_vec = convert(Vector{tType},collect(tType,tspan[1]+saveat:saveat:(tspan[end]-saveat)))
        end
    else
        saveat_vec =  convert(Vector{tType},collect(saveat))
    end

    if !isempty(saveat_vec) && saveat_vec[end] == tspan[2]
        pop!(saveat_vec)
    end

    if !isempty(saveat_vec) && saveat_vec[1] == tspan[1]
        save_ts = sort(unique([saveat_vec;T]))
    else
        save_ts = sort(unique([t0;saveat_vec;T]))
    end

    if T < save_ts[end]
        error("Final saving timepoint is past the solving timespan")
    end
    if t0 > save_ts[1]
        error("First saving timepoint is before the solving timespan")
    end

    if !isempty(tstops)
        error("tstops is not supported for this solver. Please use saveat instead")
    end

    if typeof(prob.u0) <: Number
        u0 = [prob.u0]
    else
        if alias_u0
            u0 = vec(prob.u0)
        else
            u0 = vec(deepcopy(prob.u0))
        end
    end

    sizeu = size(prob.u0)

    ### Fix the more general function to Sundials allowed style
    if !isinplace && (typeof(prob.u0)<:Vector{Float64} || typeof(prob.u0)<:Number)
        f! = (du,u,p,t) -> (du[:] = prob.f(u,p,t); nothing)
    elseif !isinplace && typeof(prob.u0)<:AbstractArray
        f! = (du,u,p,t) -> (du[:] = vec(prob.f(reshape(u,sizeu),p,t)); nothing)
    elseif typeof(prob.u0)<:Vector{Float64}
        f! = prob.f
    else # Then it's an in-place function on an abstract array
        f! = (du,u,p,t) -> (prob.f(reshape(du,sizeu),reshape(u,sizeu),p,t); nothing)
    end

    ures = Vector{Float64}[]
    push!(ures,u0)
    utmp = copy(u0)
    utmp2= copy(u0)
    ttmp = [t0]
    t    = [t0]
    t2   = [t0]
    save_start ? ts = [t0] : ts = typeof(t0)[]

    neq = Int32(length(u0))
    comfun = CommonFunction(f!,prob.p,neq)
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

    GC.@preserve comfun atol rtol begin

    global ___ref = comfun

    opt = lsoda_opt_t(mxstep = maxiter)
    opt.ixpr = 0
    opt.rtol = pointer(rtol)
    opt.atol = pointer(atol)
    if save_everystep
        itask_tmp = 2
    else
        itask_tmp = 1
    end
    opt.itask = itask_tmp

    function get_cfunction(comfun::T) where T
        @cfunction commonfun Cint (Cdouble, Ptr{Cdouble}, Ptr{Cdouble}, Ref{T})
    end

    fex_c = get_cfunction(comfun)

    ctx = lsoda_context_t()
    ctx.function_ = fex_c
    ctx.neq = neq
    ctx.state = 1
    ctx.data = pointer_from_objref(comfun)

    ch = ContextHandle(ctx)

    lsoda_prepare(ctx,opt)

    for k in 2:length(save_ts)
        ttmp[1] = save_ts[k]
        if t[1] < ttmp[1]
            while t[1] < ttmp[1]
                lsoda(ctx, utmp, t, ttmp[1])
                if t[1] > ttmp[1] # overstepd, interpolate back
                    t2[1] = t[1] # save step values
                    copyto!(utmp2,utmp) # save step values
                    opt.itask = 1 # change to interpolating
                    lsoda(ctx, utmp, t, ttmp[1])
                    opt.itask = itask_tmp
                    push!(ures, copy(utmp))
                    push!(ts, t[1])
                    # don't overstep the last timestep
                    if k != length(save_ts) && save_ts[k+1] > t2[1]
                        push!(ures, copy(utmp2))
                        push!(ts, t2[1])
                    end
                    copyto!(utmp, utmp2)
                    t[1] = t2[1]
                else
                    push!(ures, copy(utmp))
                    push!(ts,t[1])
                end
            end
      else
            t2[1] = t[1] # save step values
            copyto!(utmp2, utmp) # save step values
            opt.itask = 1 # change to interpolating
            lsoda(ctx, utmp, t, ttmp[1])
            opt.itask = itask_tmp
            push!(ures, copy(utmp))
            push!(ts, t[1])
            if k != length(save_ts) && save_ts[k+1] > t2[1] # don't overstep the last timestep
                push!(ures,copy(utmp2))
                push!(ts,t2[1])
            end
            copyto!(utmp,utmp2)
            t[1] = t2[1]
        end
    end

    ### Finishing Routine

    timeseries = uType[]
    save_start ? start_idx = 1 : start_idx = 2
    if typeof(prob.u0)<:Number
        for i=start_idx:length(ures)
            push!(timeseries,ures[i][1])
        end
    else
        for i=start_idx:length(ures)
            push!(timeseries,reshape(ures[i],sizeu))
        end
    end

    lsoda_free(ch)
    global ___ref = nothing
    end


    DiffEqBase.build_solution(prob, alg, ts, timeseries,
                   timeseries_errors = timeseries_errors,
                   retcode = :Success)
end
