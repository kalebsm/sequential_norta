function scenario_generator_init()

    # this should be a manual input somewhere else so that it isn't repeated
    forecast_scenario_length = 48;
    number_of_scenarios = 20;
    scenario_hour = 0;
    scenario_day = 1;
    scenario_month = 1;
    scenario_year = 2018;
    historical_load = "ercot_BA_load_actuals_2018.h5"
    forecast_load = "ercot_BA_load_forecast_day_ahead_2018.h5"
    historical_solar = "ercot_BA_solar_actuals_Existing_2018.h5"
    forecast_da_solar = "ercot_BA_solar_forecast_day_ahead_existing_2018.h5"
    forecast_2da_solar = "ercot_BA_solar_forecast_2_day_ahead_existing_2018.h5"
    historical_wind = "ercot_BA_wind_actuals_Existing_2018.h5"
    forecastd_da_wind = "ercot_BA_wind_forecast_day_ahead_existing_2018.h5"
    forecast_2da_wind = "ercot_BA_wind_forecast_day_ahead_existing_2018.h5"
    write_percentile =  1
    ModelScalingFactor = 1000

    norta_path = joinpath(dirname(@__FILE__), "..")
    scenario_data_path = joinpath(norta_path, "data")

    #=======================================================================
    READ INPUT DATA: ARPA-E PERFORM PROJECT H5 FILES
    =======================================================================#

    # Function that reads the .h5 file and binds the time index and the actuals/fore-
    # cast values into a single dataframe.

    # Load data
    load_actuals_raw = read_h5_file(joinpath(scenario_data_path, historical_load), "load");
    load_forecast_raw = read_h5_file(joinpath(scenario_data_path, "ercot_BA_load_forecast_day_ahead_2018.h5"), "load", false);

    # Solar data
    solar_actuals_raw = read_h5_file(joinpath(scenario_data_path, "ercot_BA_solar_actuals_Existing_2018.h5"), "solar");
    solar_forecast_dayahead_raw = read_h5_file(joinpath(scenario_data_path, "ercot_BA_solar_forecast_day_ahead_existing_2018.h5"), "solar", false);
    solar_forecast_2dayahead_raw = read_h5_file(joinpath(scenario_data_path, "ercot_BA_solar_forecast_2_day_ahead_existing_2018.h5"), "solar", false);

    # Wind data
    wind_actuals_raw = read_h5_file(joinpath(scenario_data_path, "ercot_BA_wind_actuals_Existing_2018.h5"), "wind");
    wind_forecast_dayahead_raw = read_h5_file(joinpath(scenario_data_path, "ercot_BA_wind_forecast_day_ahead_existing_2018.h5"), "wind", false);
    wind_forecast_2dayahead_raw = read_h5_file(joinpath(scenario_data_path, "ercot_BA_wind_forecast_2_day_ahead_existing_2018.h5"), "wind", false);

    #=======================================================================
    Compute the hourly average for the actuals data
    =======================================================================#
    # Load
    aux = compute_hourly_average_actuals(load_actuals_raw);
    load_actual_avg_raw = DataFrame();
    time_index = aux[:, :Index];
    avg_actual = aux[:, :values_mean];
    load_actual_avg_raw[!, :time_index] = time_index;
    load_actual_avg_raw[!, :avg_actual] = avg_actual;

    # Solar
    aux = compute_hourly_average_actuals(solar_actuals_raw);
    time_index = aux[:, :Index];
    avg_actual = aux[:, :values_mean];
    solar_actual_avg_raw = DataFrame();
    solar_actual_avg_raw[!, :time_index] = time_index;
    solar_actual_avg_raw[!, :avg_actual] = avg_actual;

    # Wind
    aux = compute_hourly_average_actuals(wind_actuals_raw);
    time_index = aux[:, :Index];
    avg_actual = aux[:, :values_mean];
    wind_actual_avg_raw = DataFrame();
    wind_actual_avg_raw[!, :time_index] = time_index;
    wind_actual_avg_raw[!, :avg_actual] = avg_actual;

    #=======================================================================
    ADJUST THE TIME 
    =======================================================================#
    #= For the year of 2018, adjust the time to Texas' UTC (UTC-6 or UTC-5)
    depending on daylight saving time =#

    # Load data
    load_actuals = convert_hours_2018(load_actuals_raw);
    load_actual_avg = convert_hours_2018(load_actual_avg_raw);
    load_forecast = convert_hours_2018(load_forecast_raw, false);
    ahead_factor = repeat(["two", "one"], size(load_forecast, 1) ÷ 2)
    load_forecast[!, :ahead_factor] = ahead_factor
    load_forecast_dayahead = filter(:ahead_factor => ==("one"), load_forecast)
    load_forecast_2dayahead = filter(:ahead_factor => ==("two"), load_forecast);

    # Solar data
    solar_actuals = convert_hours_2018(solar_actuals_raw);
    solar_actual_avg = convert_hours_2018(solar_actual_avg_raw);
    solar_forecast_dayahead = convert_hours_2018(solar_forecast_dayahead_raw, false);
    solar_forecast_2dayahead = convert_hours_2018(solar_forecast_2dayahead_raw, false);


    # Wind data
    wind_actuals = convert_hours_2018(wind_actuals_raw);
    wind_actual_avg = convert_hours_2018(wind_actual_avg_raw);
    wind_forecast_dayahead = convert_hours_2018(wind_forecast_dayahead_raw, false);
    wind_forecast_2dayahead = convert_hours_2018(wind_forecast_2dayahead_raw, false);

    #=======================================================================
    BIND HOURLY HISTORICAL DATA WITH FORECAST DATA
    ========================================================================#

    load_data = bind_historical_forecast(false,
        load_actual_avg,
        load_forecast_dayahead,
        load_forecast_2dayahead);

    solar_data = bind_historical_forecast(false,
        solar_actual_avg,
        solar_forecast_dayahead,
        solar_forecast_2dayahead);

    wind_data = bind_historical_forecast(false,
        wind_actual_avg,
        wind_forecast_dayahead,
        wind_forecast_2dayahead);

    #=======================================================================
    Landing probability
    =======================================================================#
    landing_probability_load = compute_landing_probability(load_data);
    landing_probability_solar = compute_landing_probability(solar_data);
    landing_probability_wind = compute_landing_probability(wind_data);

    #=======================================================================
    ADJUST LANDING PROBABILITY DATAFRAME
    =======================================================================#
    lp_load = transform_landing_probability(landing_probability_load);
    lp_solar = transform_landing_probability(landing_probability_solar);
    lp_wind = transform_landing_probability(landing_probability_wind);

    #=======================================================================
    Determine length of Decision Problem and additinal inputs
    =======================================================================#
    all_same = true;

    if all_same
        x = copy(wind_data);
        # Sort data by issue time
        sort!(x, :issue_time);
        # Group data by issue time and count occurences in every group
        df = combine(groupby(x, [:issue_time]), DataFrames.nrow => :count);
        # Filter data by count. Only keep groups with 48 entries
        df_filtered = filter(:count => ==(48), df);
        issue_times_interest = df_filtered[!, :issue_time];
        # find all forecast times for these issue times of interest
        subset_wind_data = filter(row -> row[:issue_time] in issue_times_interest, wind_data);
        subset_forecast_times = subset_wind_data[!, :forecast_time];
        unique_forecast_times = unique(subset_forecast_times);
        decision_mdl_lkd_length = length(unique_forecast_times);

        unique_issue_times = unique(subset_wind_data[!, :issue_time]);

        #define the actual landing probabilities as a vector
        left_lp_solar = transpose(lp_solar[:, 1:size(lp_load, 2) ÷ 2]);
        solar_landing_probabilities = vec(left_lp_solar);

        #define the actual landing probabilities as a vector
        left_lp_wind = transpose(lp_wind[:, 1:size(lp_load, 2) ÷ 2]);
        wind_landing_probabilities = vec(left_lp_wind);

        left_lp_load = transpose(lp_load[:, 1:size(lp_load, 2) ÷ 2]);
        load_landing_probabilities = vec(left_lp_load);

        # define the issue time tracking objects
        num_issue_times = length(unique_issue_times)
        issue_idcs = 1:num_issue_times

        # initialize an array of of issue times for saving the marginal probabilities
        load_marginals_by_issue = Array{DataFrame}(undef, num_issue_times)
        solar_marginals_by_issue = Array{DataFrame}(undef, num_issue_times)
        wind_marginals_by_issue = Array{DataFrame}(undef, num_issue_times)

        # loop through the wind_data and extract the marginal probability dataframes
        for i in issue_idcs
            current_issue = unique_issue_times[i]
            load_marginals_by_issue[i] = filter(row -> row[:issue_time] == current_issue, load_data)
            solar_marginals_by_issue[i] = filter(row -> row[:issue_time] == current_issue, solar_data)
            wind_marginals_by_issue[i] = filter(row -> row[:issue_time] == current_issue, wind_data)
        end

        # filter the load_data, solar_data, and wind_data by unique_issue_times
        load_data_upd = filter(row -> row[:issue_time] in unique_issue_times, load_data);
        solar_data_upd = filter(row -> row[:issue_time] in unique_issue_times, solar_data);
        wind_data_upd = filter(row -> row[:issue_time] in unique_issue_times, wind_data);

        corr_forecast_issue_times = wind_data_upd[:, [:issue_time, :forecast_time]];
    else
        error("The data issue and forecast times are not the same for all of load, solar, and wind");
    end

    # for the actuals and DLAC calculations, determine capacity factors at correct model times
    forecast2model_indices = findall(in(unique_forecast_times), load_actual_avg[!, :time_index])

    max_solar_actual = maximum(solar_actual_avg[!, :avg_actual]);
    max_wind_actual = maximum(wind_actual_avg[!, :avg_actual]);

    load_actual_avg_GW = load_actual_avg[forecast2model_indices, :avg_actual] ./ ModelScalingFactor;
    solar_actual_avg_cf = solar_actual_avg[forecast2model_indices, :avg_actual] ./ max_solar_actual;
    wind_actual_avg_cf = wind_actual_avg[forecast2model_indices, :avg_actual] ./ max_wind_actual;

    # actuals_df = DataFrame(load = load_actual_avg_GW .*ModelScalingFactor, solar = solar_actual_avg_cf, 
    #                 wind = wind_actual_avg_cf)

    # # print to csv
    # CSV.write("actuals.csv", actuals_df)

    #=======================================================================
    Perform Cholesky Decomposition to get Lower Triangular Correlation Matrix
    =======================================================================#
    M_load = generate_lower_triangular_correlation(lp_load, issue_idcs, decision_mdl_lkd_length, false);
    M_solar, sunny_decision_hours = generate_lower_triangular_correlation(lp_solar, issue_idcs, decision_mdl_lkd_length, true);
    M_wind = generate_lower_triangular_correlation(lp_wind, issue_idcs, decision_mdl_lkd_length, false);


    #=======================================================================
    DEFINE INDICES, DATETIMES, ISSUE SETS FOR NORTA SCENARIOS AND STOCASTIC SIM
    =======================================================================#
    # initialize the start date
    start_date = DateTime(string(scenario_year) * "-" * string(scenario_month) * "-" * string(scenario_day) * "T" * string(scenario_hour));





    #=======================================================================
    INITIALIZE THE DICTIONARY TO SAVE ALL GENERATOR INFORMATION
    everthing used in the rolling horizon loop must be initialized
    in the dictionary
    =======================================================================#
    # create a dictionary to hold all the generator information
    scen_generator_info = Dict()
    scen_generator_info["unique_forecast_times"] = unique_forecast_times
    scen_generator_info["unique_issue_times"] = unique_issue_times
    scen_generator_info["start_date"] = start_date
    scen_generator_info["corr_forecast_issue_times"] = corr_forecast_issue_times
    scen_generator_info["forecast_scenario_length"] = forecast_scenario_length
    scen_generator_info["number_of_scenarios"] = number_of_scenarios
    scen_generator_info["M_load"] = M_load
    scen_generator_info["M_solar"] = M_solar
    scen_generator_info["M_wind"] = M_wind
    scen_generator_info["load_marginals_by_issue"] = load_marginals_by_issue
    scen_generator_info["solar_marginals_by_issue"] = solar_marginals_by_issue
    scen_generator_info["wind_marginals_by_issue"] = wind_marginals_by_issue
    scen_generator_info["load_landing_probabilities"] = load_landing_probabilities
    scen_generator_info["solar_landing_probabilities"] = solar_landing_probabilities
    scen_generator_info["wind_landing_probabilities"] = wind_landing_probabilities
    scen_generator_info["sunny_decision_hours"] = sunny_decision_hours
    scen_generator_info["load_actual_avg"] = load_actual_avg
    scen_generator_info["solar_actual_avg"] = solar_actual_avg
    scen_generator_info["wind_actual_avg"] = wind_actual_avg
    scen_generator_info["load_actual_avg_GW"] = load_actual_avg_GW
    scen_generator_info["solar_actual_avg_cf"] = solar_actual_avg_cf
    scen_generator_info["wind_actual_avg_cf"] = wind_actual_avg_cf
    scen_generator_info["decision_mdl_lkd_length"] = decision_mdl_lkd_length
    
    return scen_generator_info
end


# # now write the scen_generator_info but switch it so that you are saving the objects = scen_generator_info[etc]
# # Save the objects from scen_generator_info into individual variables
# unique_forecast_times = scen_generator_info["unique_forecast_times"]
# unique_issue_times = scen_generator_info["unique_issue_times"]
# start_date = scen_generator_info["start_date"]
# corr_forecast_tissue_times = scen_generator_info["corr_forecast_tissue_times"]
# forecast_scenario_length = scen_generator_info["forecast_scenario_length"]
# number_of_scenarios = scen_generator_info["number_of_scenarios"]
# M_load = scen_generator_info["M_load"]
# M_solar = scen_generator_info["M_solar"]
# M_wind = scen_generator_info["M_wind"]
# load_marginals_by_issue = scen_generator_info["load_marginals_by_issue"]
# solar_marginals_by_issue = scen_generator_info["solar_marginals_by_issue"]
# wind_marginals_by_issue = scen_generator_info["wind_marginals_by_issue"]
# load_landing_probabilities = scen_generator_info["load_landing_probabilities"]
# solar_landing_probabilities = scen_generator_info["solar_landing_probabilities"]
# wind_landing_probabilities = scen_generator_info["wind_landing_probabilities"]
# sunny_decision_hours = scen_generator_info["sunny_decision_hours"]
# load_actual_avg = scen_generator_info["load_actual_avg"]
# solar_actual_avg = scen_generator_info["solar_actual_avg"]
# wind_actual_avg = scen_generator_info["wind_actual_avg"]
# load_actual_avg_GW = scen_generator_info["load_actual_avg_GW"]
# solar_actual_avg_cf = scen_generator_info["solar_actual_avg_cf"]
# wind_actual_avg_cf = scen_generator_info["wind_actual_avg_cf"]