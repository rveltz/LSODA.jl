abstract type AbstractLSODAHandle end

mutable struct ContextHandle <: AbstractLSODAHandle
    ctx::lsoda_context_t
    freed::Bool
    function (::Type{ContextHandle})(ctx::lsoda_context_t)
        h = new(ctx,false)
        finalizer(release_handle,h)
        return h
    end
end
release_handle(ch::ContextHandle) = lsoda_free(ch)

function lsoda_free(ch::ContextHandle)
    if !ch.freed
        lsoda_free(ch.ctx)
        ch.freed = true
    end
    nothing
end

# Now wrap the rest of the APIs for convenience
lsoda_reset(ch::ContextHandle) = lsoda_reset(ch.ctx)
lsoda_prepare(ch::ContextHandle,opt::lsoda_opt_t) = lsoda_prepare(ch.ctx,opt)
lsoda(ch::ContextHandle,y::Vector,t::Vector{Float64},tout) = lsoda(ch.ctx,y,t,tout)
