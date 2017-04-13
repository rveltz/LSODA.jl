using Parameters, Compat

abstract AbstractLSODAObject

@with_kw type lsoda_common_t 
    yh::Ptr{Ptr{Cdouble}}= C_NULL
    wm::Ptr{Ptr{Cdouble}}= C_NULL
    ewt::Ptr{Cdouble}= C_NULL
    savf::Ptr{Cdouble}= C_NULL
    acor::Ptr{Cdouble}= C_NULL
    ipvt::Ptr{Cint}= C_NULL
    memory::Ptr{Void}= C_NULL
    h::Cdouble = 0.
    hu::Cdouble = 0.
    rc::Cdouble = 0.
    tn::Cdouble = 0.
    tsw::Cdouble = 0.
    pdnorm::Cdouble = 0.
    crate::Cdouble = 0.
    el::NTuple{14,Cdouble} = ntuple(x->Cdouble(0), 14)
    elco::NTuple{13,NTuple{14,Cdouble}} = ntuple(x->ntuple(x->Cdouble(0), 14),13)
    tesco::NTuple{13,NTuple{4,Cdouble}} = ntuple(x->ntuple(x->Cdouble(0), 4),13)
    hold::Cdouble = 0.
    rmax::Cdouble = 0.
    pdest::Cdouble = 0.
    pdlast::Cdouble = 0.
    ialth::Cint = 0
    ipup::Cint = 0
    nslp::Cint = 0
    icount::Cint = 0
    irflag::Cint = 0
    imxer::Cint = 0
    illin::Cint = 0
    nhnil::Cint = 0
    nslast::Cint = 0
    jcur::Cint = 0
    meth::Cint = 0
    mused::Cint = 0
    nq::Cint = 0
    nst::Cint = 0
    ncf::Cint = 0
    nfe::Cint = 0
    nje::Cint = 0
    nqu::Cint = 0
    miter::Cint = 0
end

@with_kw type lsoda_opt_t 
	  ixpr::Cint = 0
    mxstep::Cint = 10000
    mxhnil::Cint = 0
    mxordn::Cint = 0
    mxords::Cint = 0
    tcrit::Cdouble = 0.
    h0::Cdouble = 0.
    hmax::Cdouble = 0.
    hmin::Cdouble = 0.
    hmxi::Cdouble = 0.
    itask::Cint = 0
    rtol::Ptr{Cdouble} = C_NULL
    atol::Ptr{Cdouble} = C_NULL
end

typealias _lsoda_f Ptr{Void}

@with_kw type lsoda_context_t 
    function_::_lsoda_f = C_NULL
    data::Ptr{Void} = C_NULL ##
    neq::Cint = 0
    state::Cint = 0
    error::Cstring = C_NULL
    common::Ptr{lsoda_common_t} = C_NULL
    opt::Ptr{lsoda_opt_t} = C_NULL
end
typealias lsoda_context_t_ptr Ptr{lsoda_context_t}

type UserFunctionAndData
    func::Function
    data::Any
    neq::Cint
    UserFunctionAndData(func::Function, data::Any, neq::Cint) = new(func, data, neq)
end

# UserFunctionAndData(func::Function) = func
# UserFunctionAndData(func::Function, data::Void) = func
# UserFunctionAndData(func::Function, data::Void, neq::Cint) = func


type Context_lsoda <: AbstractLSODAObject
    handle::Ptr{lsoda_context_t}

    #Default constructor to create a Stinger data structure
    function Context_lsoda()
        s = new(ccall((:lsoda_create_ctx,liblsoda),Ptr{lsoda_context_t},()))
        finalizer(s, lsoda_free)
        s
    end
end

type Opt_lsoda <: AbstractLSODAObject
    handle::Ptr{lsoda_opt_t}

    #Default constructor to create a Stinger data structure
    function Opt_lsoda()
        s = new(ccall((:lsoda_create_opt,liblsoda),Ptr{lsoda_opt_t},()))
        finalizer(s, lsoda_free)
        s
    end
end
##################################################################
function lsoda_prepare(ctx::lsoda_context_t,opt::lsoda_opt_t)
  return ccall((:lsoda_prepare,liblsoda),Cint,
    (Ptr{lsoda_context_t},Ptr{lsoda_opt_t}),
    Ref(ctx),Ref(opt))
end

function lsoda_prepare(ctx::Ptr{lsoda_context_t},opt::Ptr{lsoda_opt_t})
  return ccall((:lsoda_prepare,liblsoda),Cint,
    (Ptr{lsoda_context_t},Ptr{lsoda_opt_t}),
    (ctx),(opt))
end

lsoda_prepare(ctx::Context_lsoda,opt::Opt_lsoda)=lsoda_prepare(ctx.handle,opt.handle)

##################################################################
function lsoda(ctx::lsoda_context_t,y::Vector,t::Vector{Float64},tout)
  return ccall((:lsoda,liblsoda),Cint,
    (Ptr{lsoda_context_t},Ptr{Cdouble},Ptr{Cdouble},Cdouble),
    Ref(ctx),y,t,tout[1])
end

function lsoda(ctx::Ptr{lsoda_context_t},y::Vector,t::Vector{Float64},tout)
  return ccall((:lsoda,liblsoda),Cint,
    (Ptr{lsoda_context_t},Ptr{Cdouble},Ptr{Cdouble},Cdouble),ctx,y,t,tout[1])
end

lsoda(ctx::Context_lsoda,y::Vector,t::Vector{Float64},tout)=lsoda(ctx.handle,y,t,tout)
##################################################################
function lsoda_reset(ctx::lsoda_context_t)
	ccall((:lsoda_reset,liblsoda),Void,(Ptr{lsoda_context_t},),Ref(ctx))
end

function lsoda_reset(ctx::Ptr{lsoda_context_t})
	ccall((:lsoda_reset,liblsoda),Void,(Ptr{lsoda_context_t},),ctx)
end
##################################################################
function lsoda_free(ctx::lsoda_context_t)
	ccall((:lsoda_free,liblsoda),Void,(Ptr{lsoda_context_t},),Ref(ctx))
    nothing
end

function lsoda_free(ctx::Ptr{lsoda_context_t})
	ccall((:lsoda_free,liblsoda),Void,(Ptr{lsoda_context_t},),ctx)
    nothing
end

function lsoda_free(opt::Ptr{lsoda_opt_t})
	# println("--> lsoda_free = ",opt)
	ccall((:lsoda_free_opt,liblsoda),Void,(Ptr{lsoda_opt_t},),opt)
    nothing
end

function lsoda_free{T<: AbstractLSODAObject}(x::T)
    # To prevent segfaults
    # println("--> lsoda_free = ",x)
    if x.handle != C_NULL
        lsoda_free(x.handle)
    end
end
##################################################################
function lsoda_create_ctx()
		return ccall((:lsoda_create_ctx,liblsoda),Ptr{lsoda_context_t},())
end

function lsoda_create_opt()
		return ccall((:lsoda_create_opt,liblsoda),Ptr{lsoda_opt_t},())
end
##################################################################