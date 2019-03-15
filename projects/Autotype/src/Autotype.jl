module Autotype

using MacroTools: splitstructdef
using InteractiveUtils: subtypes

export @autotype

macro autotype(typedef)
    return esc(autotype(typedef))
end

macro autotype(s::Symbol, typedef)
    println("YAHOO")
    return esc(autotype(typedef, s))
end

function autotype(typedef, s=nothing)
    sp = make_parametric(typedef, s)
    new_typ = :($(sp[:name]){$(sp[:params]...)})
    type_def =
    :($(Expr(:struct,
             sp[:mutable],
             Expr(:<:, new_typ, sp[:supertype]),
             Expr(:block, sp[:fields]...))))
                  #inner_constr,
                  #((parametric &&
                  #  all_type_vars_present(type_vars, [args; kwargs]))
                  # ? [straight_constr] : [])...))))
end

#TODO pass module
function _typetest(parent_type)
    parent_type == Any || isdefined(@__MODULE__, parent_type) && length(subtypes(eval(parent_type))) != 0
end

function make_parametric(typedef, s)
    sp = splitstructdef(typedef)
    type_counter = 1
    new_fields = []
    println(typeof(s))
    @show s
    function new_type(parent)
        if !(s === nothing)
            new_ty = Symbol(s, type_counter)
            type_counter += 1
        else
            new_ty = gensym()
        end
        new_ty
    end
    function add_type(name, parent_type)
            # Case 1: Type parameter already specified, type is an existing type, and type is not concrete
        else
            # Case 2: New type parameter already specified or is concrete
            type = parent_type
            param = parent_type
        end
        type, param
    end
    new_fields = []
    new_params = []
    for (name, parent_type) in sp[:fields]
        if _typetest(parent_type)
            type = new_type(parent_type)
            param = :($type <: $parent_type)
        type, param = add_type(name, parent_type)
        push!(new_fields, :($name::$type))
        if !(param in new_params)
            push!(new_params, param)
        end
    end
    sp[:fields] = new_fields
    sp[:params] = new_params
    sp



    #if type_counter == 1
    #    # Has to special-case the "no type parameters" case because of
    #    # https://github.com/JuliaLang/julia/issues/20878
    #    return (typ, typ_def, args, kwargs)
    #else
    #    return (new_typ, :($new_typ($(typed_args...); $(typed_kwargs...))),
    #            typed_args, typed_kwargs)
    #end
end

end
