abstract LSODAAlgorithm <: AbstractODEAlgorithm
immutable LSODAAlg <: LSODAAlgorithm end

## Common Interface Solve Functions

function solve{uType,tType,isinplace,F}(
    prob::AbstractODEProblem{uType,tType,isinplace,F},
    alg::LSODAAlgorithm,
    timeseries=[],ts=[],ks=[];
    abstol=1/10^6,reltol=1/10^3,
    saveat=Float64[],maxiter=Int(1e5),
    timeseries_errors=true,save_timeseries=true,
    userdata=nothing,kwargs...)

    tspan = prob.tspan
    t0 = tspan[1]
    T = tspan[end]

    save_ts = sort(unique([t0;saveat;T]))

    if T < save_ts[end]
        error("Final saving timepoint is past the solving timespan")
    end
    if t0 > save_ts[1]
        error("First saving timepoint is before the solving timespan")
    end

    if typeof(prob.u0) <: Number
        u0 = [prob.u0]
    else
        u0 = vec(deepcopy(prob.u0))
    end

    sizeu = size(prob.u0)

    ### Fix the more general function to Sundials allowed style
    if !isinplace && (typeof(prob.u0)<:Vector{Float64} || typeof(prob.u0)<:Number)
        f! = (t,u,du,userdata) -> (du[:] = prob.f(t,u); nothing)
    elseif !isinplace && typeof(prob.u0)<:AbstractArray
        f! = (t,u,du,userdata) -> (du[:] = vec(prob.f(t,reshape(u,sizeu))); nothing)
    elseif typeof(prob.u0)<:Vector{Float64}
        f! = (t,u,du,userdata) -> prob.f(t,u,du)
    else # Then it's an in-place function on an abstract array
        f! = (t,u,du,userdata) -> (prob.f(t,reshape(u,sizeu),reshape(du,sizeu));
                          u = vec(u); du=vec(du); nothing)
    end

    ures = Vector{Vector{Float64}}()
    push!(ures,u0)
    utmp = copy(u0)
    ttmp = [t0]
    t    = [t0]
    ts   = [t0]

    neq = Int32(length(u0))
    userfun = UserFunctionAndData(f!, userdata,neq)

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

    opt = lsoda_opt_t()
    opt.ixpr = 0
    opt.rtol = pointer(rtol)
    opt.atol = pointer(atol)
    opt.itask = 1

    const fex_c = cfunction(lsodafun,Cint,(Cdouble,Ptr{Cdouble},Ptr{Cdouble},Ref{typeof(userfun)}))

    ctx = lsoda_context_t()
    ctx.function_ = fex_c
    ctx.neq = neq
    ctx.state = 1
    ctx.data = pointer_from_objref(userfun)

    lsoda_prepare(ctx,opt)

    # The Inner Loops : Style depends on save_timeseries
    if save_timeseries
        #=
        for k in 2:length(save_ts)
            looped = false
            while tout[end] < save_ts[k]
                looped = true
                flag = @checkflag CVode(mem,
                                save_ts[k], utmp, tout, CV_ONE_STEP)
                push!(ures,copy(utmp))
                push!(ts, tout...)
            end
            if looped
                # Fix the end
                flag = @checkflag CVodeGetDky(
                                        mem, save_ts[k], Cint(0), ures[end])
                ts[end] = save_ts[k]
            else # Just push another value
                flag = @checkflag CVodeGetDky(
                                        mem, save_ts[k], Cint(0), utmp)
                push!(ures,copy(utmp))
                push!(ts, save_ts[k]...)
            end
        end
        =#
    else # save_timeseries == false, so use saveat style
      for k in 2:length(save_ts)
        ttmp[1] = save_ts[k]
        lsoda(ctx,utmp,t,ttmp[1])
        push!(ures,copy(utmp))
      end
      ts = save_ts
    end

    ### Finishing Routine

    timeseries = Vector{uType}(0)
    if typeof(prob.u0)<:Number
        for i=1:length(ures)
            push!(timeseries,ures[i][1])
        end
    else
        for i=1:length(ures)
            push!(timeseries,reshape(ures[i],sizeu))
        end
    end

    build_solution(prob,alg,ts,timeseries,
                      timeseries_errors = timeseries_errors)
end
