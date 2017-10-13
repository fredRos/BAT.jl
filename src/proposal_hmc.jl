# This file is a part of BAT.jl, licensed under the MIT License (MIT).


"""
My doc for HMCProposalFunction
"""
struct HMCProposalFunction{D<:Distribution{Multivariate},SamplerF<:Function,S<:Sampleable} <: AbstractProposalDist
    d::D
    sampler_f::SamplerF
    s::S
    ϵ::Float64
    n::Int

    function HMCProposalFunction(d::D, ϵ::Float64, n::Int, sampler_f::SamplerF = bat_sampler) where {D<:Distribution{Multivariate}, SamplerF}
        s = sampler_f(d)
        new{D,SamplerF, typeof(s)}(d, sampler_f, s, ϵ, n)
    end

end

export HMCProposalFunction

Base.issymmetric(::HMCProposalFunction) = true

nparams(hmc::HMCProposalFunction) = length(hmc.d)

function proposal_rand(rng::AbstractRNG, hmc::HMCProposalFunction,                 params_new::AbstractVecOrMat, params_old::AbstractVecOrMat)
    #
end
