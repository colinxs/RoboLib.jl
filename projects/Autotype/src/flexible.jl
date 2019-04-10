using MacroTools: splitstructdef, combinedef, prettify
using InteractiveUtils: subtypes

macro flextype(typedef)
    return esc(flextype(typedef))
end

function _immset(value, name::Symbol, ob::T) where T
    T((field === name ? value : getproperty(ob, field) for field in propertynames(ob))...)
end

function flextype(typedef, s=nothing)
    structdef = splitstructdef(typedef)


    # names and types of the fields in the original struct def
    names = Tuple(f[1] for f in structdef[:fields])
    types = Tuple(f[2] for f in structdef[:fields])

    # the type of our flexible struct's "_vals" field
    # "tuptype" has the same fieldnames/types as the original struct
    tuptype = :(NamedTuple{$names, $(Expr(:curly, :Tuple, types...))})
    # the corresponding constructor for tuptype
    tupctor = Expr(:tuple, (:($name=$name) for name::Symbol in names)...)

    # the flexible type's inner constructor
    ctordef = Dict{Symbol, Any}(
        :name=>Symbol(structdef[:name]),
        :args=>Tuple(:($name::$type) for (name, type) in structdef[:fields]),
        :whereparams=>Tuple(structdef[:params]),
        :kwargs=>[],
        :body=> :(new{$tuptype}($tupctor))
    )

    # the flexible type's definition
    ex = quote
        struct $(structdef[:name]){NT<:NamedTuple}
            _vals::NT
            $(combinedef(ctordef))
        end
        Base.getproperty(x::$(structdef[:name]), name::Symbol) = getproperty(getfield(x, :_vals), name)
    end

    # add voodoo if the original struct def is mutable
    if structdef[:mutable]
        ex.args[2].args[1] = true # same as changing above type definition to "mutable struct"

        # What follows is an absolutely ridiculous hack. I am not proud.
        setter = quote
            # define a setter for our flexible type
            function Base.setproperty!(x::$(structdef[:name]), name::Symbol, value)
                # we create create a whole new flexible type with a "_vals" field containing all the original
                # values expect for "name" which now equals "value", then set the flexible types "_vals" field to
                # the new struct's "_vals_ field, throwing away the new struct itself.
                # Why? Because the flexible type's field is of type "NamedTuple" i.e. it can contain any type,
                # but the original struct def may have had type parameters. We use the constructor for the
                # flexible type to assure that "value" is of the correct type. We COULD change the type parameter
                # for the flexible struct def to encapsulate the type parameters in the original struct def
                # (i.e. NamedTuple{(:x,), Tuple{(Int,)}} instead of NamedTuple), but then changing the types/fields
                # of the flexible struct yields errors about invalid struct definitions. We'd be back to square one.
                # So we leave the type parameter general, and use the constructor to enforce types. There is 110%
                # a better way to do this, but for now the external behavior of our flexible type at least matches the behavior of
                # the original struct def.
                newx = $(structdef[:name])((field === name ? value : getproperty(getfield(x, :_vals), field) for field in propertynames(getfield(x, :_vals)))...)
                setfield!(x, :_vals, getfield(newx, :_vals))
                x
            end
        end
        push!(ex.args, setter)
    end
    ex
end

@flextype mutable struct Foo{X, Y<:Number}
    x::X
    y::Y
end

function test()
    obj = Foo(1, 2)
    @assert obj.x == 1
    @assert obj.y == 2
    obj.x = 10
    obj.y = 20
    @assert obj.x == 10
    @assert obj.y == 20

    try
        obj.y = "hello"
    catch e
        errstr = sprint(showerror, e)
        expectederrstr = "MethodError: no method matching Foo(::Int64, ::String)\nClosest candidates are:\n  Foo(::X, !Matched::Y<:Number) where {X, Y<:Number} at none:0"
        @assert errstr == expectederrstr
    end
end