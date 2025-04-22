# Sequential Scenario Generation with Copulas 
# 
# Kaleb Smith, based on code from Hugo S. de Araujo
# March 6th 
################################################################################
module SequentialNorta

# Import all required packages. 
begin
    using CSV
    using DataFrames
    using Dates
    using DelimitedFiles
    using Distributions
    using HDF5
    # using LaTeXStrings
    using LinearAlgebra
    using LinearSolve
    using Random
    using Statistics
    using StatsBase
    using Plots
    using Tables
    using TSFrames
    using TimeZones
end

# include functions
include(joinpath(@__DIR__, "..", "src", "fct_bind_historical_forecast.jl"));
include(joinpath(@__DIR__, "..", "src", "fct_compute_hourly_average_actuals.jl"));
include(joinpath(@__DIR__, "..", "src", "fct_compute_landing_probability.jl"));
include(joinpath(@__DIR__, "..", "src", "fct_convert_hours_2018.jl"));
include(joinpath(@__DIR__, "..", "src", "fct_convert_ISO_standard.jl"));
include(joinpath(@__DIR__, "..", "src", "fct_convert_land_prob_to_data.jl"));
include(joinpath(@__DIR__, "..", "src", "fct_generate_probability_scenarios.jl"));
# include(joinpath(@__DIR__, "..", "src", "fct_plot_correlation_heatmap.jl"));
# include(joinpath(@__DIR__, "..", "src", "fct_plot_historical_landing.jl"));
# include(joinpath(@__DIR__, "..", "src", "fct_plot_historical_synthetic_autocorrelation.jl"));
# include(joinpath(@__DIR__, "..", "src", "fct_plot_correlogram_landing_probability.jl"));
# include(joinpath(@__DIR__, "..", "src", "fct_plot_scenarios_and_actual.jl"));
include(joinpath(@__DIR__, "..", "src", "fct_read_h5_file.jl"));
include(joinpath(@__DIR__, "..", "src", "fct_read_input_file.jl"));
include(joinpath(@__DIR__, "..", "src", "fct_transform_landing_probability.jl"));
include(joinpath(@__DIR__, "..", "src", "fct_write_percentiles.jl"));
include(joinpath(@__DIR__, "..", "src", "fct_generate_lower_triangular_correlation.jl"));
include(joinpath(@__DIR__, "..", "src", "fct_generate_norta_scenarios.jl"));
include(joinpath(@__DIR__, "..", "src", "fct_scenario_generator_init.jl"));
include(joinpath(@__DIR__, "..", "src", "fct_get_well_defined_covariance_matrix.jl"));


export read_h5_file
export fct_compute_hourly_average_actuals
export convert_hours_2018
export bind_historical_forecast
export compute_landing_probability
export transform_landing_probability
export generate_lower_triangular_correlation
export generate_norta_scenarios
export scenario_generator_init
export get_well_defined_covariance_matrix

end # module
