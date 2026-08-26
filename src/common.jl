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

# Normalize the `verbose` keyword to a `DEVerbosity` (the SciMLLogging-based
# verbosity specifier from DiffEqBase). Accepts a verbosity preset (e.g.
# `Standard()`), a `DEVerbosity` directly, or a `Bool` for backwards compatibility.
_process_verbose_param(v::SciMLLogging.AbstractVerbosityPreset) = DEVerbosity(v)
_process_verbose_param(v::Bool) = v ? DEVerbosity() : DEVerbosity(SciMLLogging.None())
_process_verbose_param(v::DEVerbosity) = v

function _lsoda_retcode(state)
    state > 0 && return SciMLBase.ReturnCode.Success
    state == -1 && return SciMLBase.ReturnCode.MaxIters
    state in (-4, -5) && return SciMLBase.ReturnCode.ConvergenceFailure
    return SciMLBase.ReturnCode.Failure
end

function DiffEqBase.__solve(
    prob::DiffEqBase.AbstractODEProblem{uType,tupType,isinplace},
    alg::LSODAAlgorithm,
    timeseries=[],ts=[],ks=[];

    verbose = Standard(),
    abstol=1/10^6,reltol=1/10^3,
    tstops=Float64[],
    d_discontinuities=Float64[],
    saveat = Float64[], maxiters = Int(1.0e5),
    dtmin=0.0, dtmax=0.0,
    callback=nothing,
    timeseries_errors=true,
    save_everystep=isempty(saveat),
    save_start = save_everystep || isempty(saveat) || typeof(saveat) <: Number ? true : prob.tspan[1] in saveat,
    userdata=nothing,
    alias_u0=false,
    kwargs...) where {uType,tupType,isinplace}

    tType = eltype(tupType)

    verbose = _process_verbose_param(verbose)

    warned = !isempty(kwargs) && check_keywords(alg, kwargs, warnlist)
    if !(typeof(prob.f) <: DiffEqBase.AbstractParameterizedFunction)
        if DiffEqBase.has_tgrad(prob.f)
            @SciMLMessage("Explicit t-gradient given to this stiff solver is ignored.",
                verbose, :mismatched_input_output_type)
            warned = true
        end
        if DiffEqBase.has_jac(prob.f)
            @SciMLMessage("Explicit Jacobian given to this stiff solver is ignored.",
                verbose, :mismatched_input_output_type)
            warned = true
        end
    end
    warned && warn_compat()

    if prob.f.mass_matrix != I
        error("This solver is not able to use mass matrices.")
    end

    if callback != nothing || :callback in keys(prob.kwargs)
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

    tstops_vec = convert(Vector{tType}, sort(unique([collect(tstops); collect(d_discontinuities)])))
    filter!(t -> t0 < t < T, tstops_vec)
    # Always treat T as a tstop — the solver should never step past the end
    push!(tstops_vec, T)

    all_targets = sort(unique([save_ts; tstops_vec]))
    save_set = Set(save_ts)
    tstops_set = Set(tstops_vec)

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

    opt = lsoda_opt_t(mxstep = maxiters)
    opt.ixpr = 0
    opt.rtol = pointer(rtol)
    opt.atol = pointer(atol)
    opt.hmin = Float64(dtmin)
    opt.hmax = Float64(dtmax)
    itask_tmp = save_everystep ? 5 : 4
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

    tstop_idx = 1
    retcode = SciMLBase.ReturnCode.Success

    for k in 2:length(all_targets)
        ttmp[1] = all_targets[k]
        is_save_point = all_targets[k] in save_set
        is_tstop = all_targets[k] in tstops_set

        # Update tcrit to next tstop ahead of current time
        while tstop_idx <= length(tstops_vec) && tstops_vec[tstop_idx] <= t[1]
            tstop_idx += 1
        end
        if tstop_idx <= length(tstops_vec)
            opt.tcrit = tstops_vec[tstop_idx]
        end

        if t[1] < ttmp[1]
            if is_tstop
                # tcrit == target: solver guaranteed not to overstep
                while t[1] < ttmp[1]
                    lsoda(ctx, utmp, t, ttmp[1])
                    retcode = _lsoda_retcode(ctx.state)
                    retcode == SciMLBase.ReturnCode.Success || break
                    if save_everystep || is_save_point
                        push!(ures, copy(utmp))
                        push!(ts, t[1])
                    end
                end
            else
                # saveat-only target between tstops: solver may overstep
                # (tcrit is at the next tstop, not at this saveat point).
                # Since T is always a tstop, this is never the last target.
                while t[1] < ttmp[1]
                    lsoda(ctx, utmp, t, ttmp[1])
                    retcode = _lsoda_retcode(ctx.state)
                    retcode == SciMLBase.ReturnCode.Success || break
                    if t[1] > ttmp[1] # overstepped, interpolate back
                        t2[1] = t[1]
                        copyto!(utmp2,utmp)
                        opt.itask = 1 # interpolation mode
                        lsoda(ctx, utmp, t, ttmp[1])
                        opt.itask = itask_tmp
                        retcode = _lsoda_retcode(ctx.state)
                        retcode == SciMLBase.ReturnCode.Success || break
                        if save_everystep || is_save_point
                            push!(ures, copy(utmp))
                            push!(ts, t[1])
                        end
                        if all_targets[k+1] > t2[1]
                            push!(ures, copy(utmp2))
                            push!(ts, t2[1])
                        end
                        copyto!(utmp, utmp2)
                        t[1] = t2[1]
                    else
                        if save_everystep || is_save_point
                            push!(ures, copy(utmp))
                            push!(ts,t[1])
                        end
                    end
                end
            end
      else
            if is_tstop
                # Already at this tstop (solver landed here during a prior target).
                # No interpolation needed — just save.
                if save_everystep || is_save_point
                    push!(ures, copy(utmp))
                    push!(ts, t[1])
                end
            else
                # Already past a saveat-only target, interpolate back.
                # Since T is always a tstop, this is never the last target.
                if save_everystep || is_save_point
                    t2[1] = t[1]
                    copyto!(utmp2, utmp)
                    opt.itask = 1 # interpolation mode
                    lsoda(ctx, utmp, t, ttmp[1])
                    opt.itask = itask_tmp
                    retcode = _lsoda_retcode(ctx.state)
                    retcode == SciMLBase.ReturnCode.Success || break
                    push!(ures, copy(utmp))
                    push!(ts, t[1])
                    if all_targets[k+1] > t2[1]
                        push!(ures,copy(utmp2))
                        push!(ts,t2[1])
                    end
                    copyto!(utmp,utmp2)
                    t[1] = t2[1]
                end
            end
        end
        retcode == SciMLBase.ReturnCode.Success || break
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
                   retcode = retcode)
end
