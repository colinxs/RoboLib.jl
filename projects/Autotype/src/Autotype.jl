module Autotype

using MacroTools: splitstructdef

export @autotype

# TODO: handle type paramters not used with fields
# TODO: handle inner constructors
# TODO: handle docstrings

macro autotype(typedef)
    esc(autotype(typedef, __module__))
end

function autotype(typedef, mod)
    sp = make_parametric(typedef, mod)
    new_typ = :($(sp[:name]){$(sp[:params]...)})
    type_def =
    :($(Expr(:struct,
             sp[:mutable],
             Expr(:<:, new_typ, sp[:supertype]),
             Expr(:block, sp[:fields]...))))
end

_hasparam(t::Symbol, x) = !isnothing(findfirst(p->p===t || isa(p, Expr) && p.args[1] === t, x))

function make_parametric(typedef, mod)
    sp = splitstructdef(typedef)
    new_fields = []
    for (name, type) in sp[:fields]
        if type == Any
            # undeclared type (i.e. field "foo")
            newtype = gensym()
            push!(new_fields, :($name::$newtype))
            push!(sp[:params], :($newtype))
        elseif isdefined(mod, type)
            if isconcretetype(mod.eval(type))
                # declared concrete type (i.e. field "foo::Int")
                push!(new_fields, :($name::$type))
            else
                # declared abstract type (i.e. field "foo::Integer")
                newtype = gensym()
                push!(new_fields, :($name::$newtype))
                push!(sp[:params], :($newtype <: $type))
            end
        else
            # declared paramterized type (i.e. field "foo::T")
            push!(new_fields, :($name::$type))
            if !_hasparam(type, sp[:params])
                @warn("In definition of $(sp[:name]): declared type \"$type\" for field \"$name\" does not exist, adding it as a parameter")
                # As a convenience we add the missing type parameter, allowing definitions like:
                # @autotype struct Bar
                #   foo::T
                # end
                # equivalent to
                # struct Bar{T}
                #   foo::T
                # end
                push!(sp[:params], type)
            end
        end
    end
    sp[:fields] = new_fields
    sp
end

end # module

