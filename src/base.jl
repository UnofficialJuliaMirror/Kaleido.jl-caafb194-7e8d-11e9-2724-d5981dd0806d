"""
    KaleidoLens <: Lens

Internal abstract type for Kaleido.jl.
"""
abstract type KaleidoLens <: Lens end

_getfields(obj) = map(n -> getfield(obj, n), fieldnames(typeof(obj))) :: Tuple

function print_apply(io, f, args)
    if !get(io, :limit, false)
        # Don't show full name in REPL etc.:
        print(io, join(fullname(parentmodule(f)), '.'), '.')
    end
    print(io, nameof(f))
    if length(args) == 1
        print(io, '(')
        show(io, args[1])
        print(io, ')')
    else
        show(io, args)
    end
    return
end

_default_show(io, obj) = print_apply(io, typeof(obj), _getfields(obj))

Base.show(io::IO, lens::KaleidoLens) = _default_show(io, lens)

_tail(t) = Base.tail(t)
_tail(t::NamedTuple{names}) where names = NamedTuple{Base.tail(names)}(t)

struct _Zip{T1, T2}
    it1::T1
    it2::T2
end

const EmptyTuple = Union{Tuple{}, NamedTuple{(),Tuple{}}}
const EmptyItr = Union{EmptyTuple, _Zip{<:EmptyTuple, <:EmptyTuple}}
const AnyItr = Union{Tuple, NamedTuple, _Zip}
const _zip = _Zip

@inline _tail(it::_Zip) = _Zip(_tail(it.it1), _tail(it.it2))
@inline Base.getindex(it::_Zip, i) = (it.it1[i], it.it2[i])

@inline _mapfoldl(::Any, ::Any, ::EmptyItr, init) = init
@inline _mapfoldl(f, op, xs::AnyItr, init) =
    _mapfoldl(f, op, _tail(xs), op(init, f(xs[1])))

@inline _foldl(op, xs, init) = _mapfoldl(identity, op, xs, init)
