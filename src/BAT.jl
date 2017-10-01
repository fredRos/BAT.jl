# This file is a part of BAT.jl, licensed under the MIT License (MIT).

__precompile__(true)

module BAT

include("shims.jl")
include("rng.jl")
include("distributions.jl")
include("util.jl")
include("extendablearray.jl")
include("logging.jl")
include("execcontext.jl")
include("onlineuvstats.jl")
include("onlinemvstats.jl")
include("spatialvolume.jl")
include("parambounds.jl")
include("proposaldist.jl")
include("target_density.jl")
include("target_subject.jl")
include("target_const.jl")
include("target_product.jl")
include("target_distribution.jl")
include("algorithms.jl")
include("data_vector.jl")
include("density_sample.jl")
include("mcmc_chain.jl")
include("mcmc_sampleid.jl")
include("mcmc_stats.jl")
include("mcmc_convergence.jl")
include("mcmc_tuner.jl")
include("mcmc_accrejstate.jl")
include("mh_sampler.jl")
include("mh_tuner.jl")
include("plots_recipes.jl")

Logging.@enable_logging

end # module
