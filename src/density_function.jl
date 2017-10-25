# This file is a part of BAT.jl, licensed under the MIT License (MIT).


# ToDo: Add `density_logvalgrad!` to support HMC, etc.


doc"""
    AbstractDensityFunction

The following functions must be implemented for subtypes:

* `BAT.nparams`
* `BAT.unsafe_density_logval`

In some cases, it may be desirable to override the default implementations
of the functions

* `BAT.exec_capabilities`
* `BAT.unsafe_density_logval!`
"""
abstract type AbstractDensityFunction end  XXXXX check
export AbstractDensityFunction


doc"""
    param_bounds(density::AbstractDensityFunction)::AbstractParamBounds

Get the parameter bounds of `density`. See `density_logval!` for the
implications and handling of the bounds.

Use

   new_density = density[bounds::ParamVolumeBounds]

to create a new density function with additional bounds.
"""
function param_bounds(density::AbstractDensityFunction)
    NoParamBounds(nparams(density))
end
export param_bounds


doc"""
    getindex(density::AbstractDensityFunction, bounds::ParamVolumeBounds)

Limit `density` to `bounds`. See `param_bounds` and `density_logval!`.
"""
Base.getindex(density::AbstractDensityFunction, bounds::ParamVolumeBounds) =
    ConstDensity(bounds, false) * density




doc"""
    density_logval(
        density::AbstractDensityFunction,
        params::AbstractVector{<:Real},
        exec_context::ExecContext = ExecContext()
    )

Version of `density_logval` for a single parameter vector.

Do not implement `density_logval` directly for subtypes of
`AbstractDensityFunction`, implement `BAT.unsafe_density_logval` instead.

See `ExecContext` for thread-safety requirements.
"""
function density_logval(
    density::PriorDistribution,
    params::AbstractVector{<:Real},
    exec_context::ExecContext = ExecContext()
)
    !(size(params, 1) == nparams(density)) && throw(ArgumentError("Invalid length of parameter vector"))
    density_logval(density, params, exec_context)
end
export density_logval

# Assume that density_logval isn't always thread-safe, but usually remote-safe:
exec_capabilities(::typeof(density_logval), density::AbstractDensityFunction, params::AbstractVector{<:Real}) =
    exec_capabilities(unsafe_density_logval, density, params)


doc"""
    BAT.unsafe_density_logval(
        density::AbstractDensityFunction,
        params::AbstractVector{<:Real},
        exec_context::ExecContext = ExecContext()
    )

Unsafe variant of `density_logval`, implementations may rely on

* `size(params, 1) == nparams(density)`

The caller *must* ensure that these conditions are met!
"""
function unsafe_density_logval end

# Assume that density_logval isn't always thread-safe, but usually remote-safe:
exec_capabilities(::typeof(unsafe_density_logval), density::AbstractDensityFunction, params::AbstractVector{<:Real}) =
    ExecCapabilities(0, false, 0, true)




doc"""
    density_logval!(
        r::AbstractArray{<:Real},
        density::AbstractDensityFunction,
        params::AbstractMatrix{<:Real},
        exec_context::ExecContext = ExecContext()
    )

Compute log of values of a density function for multiple parameter value
vectors.

Input:

* `density`: density function
* `params`: parameter values (column vectors)
* `exec_context`: Execution context

Output is stored in

* `r`: Array of log-result values, length must match, shape is ignored

Array size requirements:

    size(params, 1) == length(r)

Note: `density_logval!` must not be called with out-of-bounds parameter
vectors (see `param_bounds`). The result of `density_logval!` for parameter
vectors that are out of bounds is implicitly `-Inf`, but for performance
reasons the output is left undefined: `density_logval!` may fail or store
arbitrary values in `r`.

Do not implement `density_logval!` directly for subtypes of
`AbstractDensityFunction`, implement `BAT.unsafe_density_logval!` instead.

See `ExecContext` for thread-safety requirements.
"""
function density_logval!(
    r::AbstractVector{<:Real},
    density::PriorDistribution,
    params::AbstractMatrix{<:Real},
    exec_context::ExecContext = ExecContext()
)
    !(size(params, 1) == nparams(density)) && throw(ArgumentError("Invalid length of parameter vector"))
    !(indices(params, 2) == indices(r, 1)) && throw(ArgumentError("Number of parameter vectors doesn't match length of result vector"))
    unsafe_density_logval(r, density, params, exec_context)
end
export density_logval!

exec_capabilities(::typeof(density_logval!), r::AbstractArray{<:Real}, density::AbstractDensityFunction, params::AbstractMatrix{<:Real}) =
    exec_capabilities(unsafe_density_logval, r, density, params)


doc"""
    BAT.unsafe_density_logval(
        density::AbstractDensityFunction,
        params::AbstractVector{<:Real},
        exec_context::ExecContext = ExecContext()
    )

Unsafe variant of `density_logval`, implementations may rely on

* `size(params, 1) == nparams(density)`
* `indices(params, 2) == indices(r, 1)`

The caller *must* ensure that these conditions are met!
"""
function unsafe_density_logval!(
    r::AbstractArray{<:Real},
    density::AbstractDensityFunction,
    params::AbstractMatrix{<:Real},
    exec_context::ExecContext
)
    # TODO: Support for parallel execution
    single_ec = exec_context # Simplistic, will have to change for parallel execution
    for i in eachindex(r, indices(params, 2))
        p = view(params, :, i) # TODO: Avoid memory allocation
        r[i] = density_logval(density, p, single_ec)
    end
    r
end

# ToDo: Derive from exec_capabilities(density_logval, density, ...)
exec_capabilities(::typeof(unsafe_density_logval!), r::AbstractArray{<:Real}, density::AbstractDensityFunction, params::AbstractMatrix{<:Real}) =
    ExecCapabilities(0, false, 0, true) # Change when default implementation of density_logval! for AbstractDensityFunction becomes multithreaded.



doc"""
    GenericDensityFunction{F} <: AbstractDensityFunction

Constructors:

    GenericDensityFunction(log_f, nparams::Int)

Turns the logarithmic density function `log_f` into a
BAT-compatible `AbstractDensityFunction`. `log_f` must support

    `log_f(params::AbstractVector{<:Real})::Real`

with `length(params) == nparams`.

It must be safe to execute `log_f` in parallel on multiple threads and
processes.
"""
struct GenericDensityFunction{F} <: AbstractDensityFunction
    log_f::F
    nparams::Int
end

export GenericDensityFunction

Base.parent(density::GenericDensityFunction) = density.log_f

nparams(density::GenericDensityFunction) = density.nparams

function unsafe_density_logval(
    density::GenericDensityFunction,
    params::AbstractVector{<:Real},
    exec_context::ExecContext = ExecContext()
)
    size(params, 1) != nparams(density) && throw(ArgumentError("Invalid number of parameters"))
    density.log_f(params)
end

exec_capabilities(::typeof(unsafe_density_logval), density::AbstractDensityFunction, params::AbstractVector{<:Real}) =
    ExecCapabilities(1, true, 1, true)



#=

mutable struct TransformedDensity{...}{
    SO<:AbstractDensityFunction,
    SN<:AbstractDensityFunction
} <: AbstractDensityFunction
   before::SO
   after::SN
   # ... transformation, Jacobi matrix of transformation, etc.
end

export TransformedDensity

...

=#
