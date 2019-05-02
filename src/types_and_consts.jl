using Parameters, Compat

@with_kw mutable struct lsoda_common_t
    yh::Ptr{Ptr{Cdouble}}= C_NULL
    wm::Ptr{Ptr{Cdouble}}= C_NULL
    ewt::Ptr{Cdouble}= C_NULL
    savf::Ptr{Cdouble}= C_NULL
    acor::Ptr{Cdouble}= C_NULL
    ipvt::Ptr{Cint}= C_NULL
    memory::Ptr{Nothing}= C_NULL
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

@with_kw mutable struct lsoda_opt_t
	  ixpr::Cint = 0
    mxstep::Cint = 0
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

const _lsoda_f = Ptr{Nothing}

@with_kw mutable struct lsoda_context_t
    function_::_lsoda_f = C_NULL
    data::Ptr{Nothing} = C_NULL ##
    neq::Cint = 0
    state::Cint = 0
    error::Cstring = C_NULL
    common::Ptr{lsoda_common_t} = C_NULL
    opt::Ptr{lsoda_opt_t} = C_NULL
end

const lsoda_context_t_ptr = Ptr{lsoda_context_t}

mutable struct UserFunctionAndData
    func::Function
    data::Any
    neq::Cint
    UserFunctionAndData(func::Function, data::Any, neq::Cint) = new(func, data, neq)
end

# UserFunctionAndData(func::Function) = func
# UserFunctionAndData(func::Function, data::Nothing) = func
# UserFunctionAndData(func::Function, data::Nothing, neq::Cint) = func

function lsoda_prepare(ctx::lsoda_context_t,opt::lsoda_opt_t)
  return ccall((:lsoda_prepare,liblsoda),Cint,
    (Ref{lsoda_context_t},Ref{lsoda_opt_t}),
    Ref(ctx),Ref(opt))
end

function lsoda(ctx::lsoda_context_t,y::Vector,t::Vector{Float64},tout)
  return ccall((:lsoda,liblsoda),Cint,
    (Ref{lsoda_context_t},Ref{Cdouble},Ref{Cdouble},Cdouble),
    Ref(ctx),y,t,tout[1])
end


function lsoda_reset(ctx::lsoda_context_t)
	ccall((:lsoda_reset,liblsoda),Nothing,(Ref{lsoda_context_t},),Ref(ctx))
end

# written to wrap lsoda_free from C library but never used in practise as
# lsoda_context_t variables are handled on Julia's side
function lsoda_free(ctx::lsoda_context_t)
		ccall((:lsoda_free,liblsoda),Nothing,(Ref{lsoda_context_t},),Ref(ctx))
    nothing
end

function lsoda_free(ctx::Ref{lsoda_context_t})
		ccall((:lsoda_free,liblsoda),Nothing,(Ref{lsoda_context_t},),(ctx))
    nothing
end
