"""
   Handle for Lsoda objects
   Wraps the reference to the pointer to the LSODA object.
   Manages automatic destruction of the referenced objects when it is
   no longer in use.
"""
immutable Handle{T <: AbstractLSODAObject}
    ptr_ref::Ref{T} # pointer to a pointer

    @compat function (::Type{Handle}){T <: AbstractLSODAObject}(ptr::T)
        h = new{T}(Ref{T}(ptr))
        finalizer(h.ptr_ref, release_handle)
        return h
    end
end

# Base.convert{T}(::Type{Ptr{T}}, h::Handle{T}) = h.ptr_ref[]
# Base.convert{T}(::Type{Ptr{Ptr{T}}}, h::Handle{T}) = convert(Ptr{Ptr{T}}, h.ptr_ref[])

release_handle{T}(ptr_ref::Ref{T}) = throw(MethodError("Freeing objects of type $T not supported"))
release_handle(ptr_ref::Ref{lsoda_context_t}) = (ptr_ref[] != C_NULL) && lsoda_free(ptr_ref)

Base.empty!{T}(h::Handle{T}) = release_handle(h.ptr_ref)
Base.isempty{T}(h::Handle{T}) = h.ptr_ref[] == C_NULL

##################################################################
#
# Convenience typealiases for Sundials handles
#
##################################################################

typealias LSODAh Handle{lsoda_context_t}
