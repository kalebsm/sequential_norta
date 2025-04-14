function generate_norta_scenarios(number_of_scen, scenario_len, date, start_ind, 
                                    active_iss, corr_forc_iss_times, d_norm, 
                                    M, current_marginals, landing_probabilities,
                                    sunny_decision_hours, is_solar=false)
    """
    generate_norta_scenarios: 

    # Arguments:
    - 

    # Returns:
    - 
    """

    percentile_column_index = startswith.(names(current_marginals), "p_");
    dim_M = size(M, 1);

    if dim_M != scenario_len
        kernel_scenario_len = dim_M;
    else
        kernel_scenario_len = scenario_len;
    end

    # get the indices of the forecasts of the active issue times
    curr_forec_indices = findall(x -> x in active_iss, corr_forc_iss_times[!,:issue_time]);

    # get the actual forecast times of the current forecast indices
    curr_forec_times = corr_forc_iss_times[curr_forec_indices, :forecast_time];
    # get the forecast times that are after the start_data
    forec_times_start_incl = filter(x -> x >= date, curr_forec_times);
    # calculate the length of the forecast times after the start date
    policy_model_len = length(forec_times_start_incl);
    policy_lookahead_len = policy_model_len - 1; # minus one always for the existing lookahead...
    policy_actuals_len = scenario_len - policy_lookahead_len;
    first_forec_decision_time_hour = curr_forec_indices[1];
    # policy_decn_hours = collect(policy_actuals_len:scenario_len);
    forecast_decision_time_hours = collect(first_forec_decision_time_hour:first_forec_decision_time_hour+scenario_len-1)

    if is_solar
        decision_time_sunny_hours = intersect(sunny_decision_hours, forecast_decision_time_hours);
        policy_time_sunny_hours = decision_time_sunny_hours .- first_forec_decision_time_hour .+ 1;
    
        # find the actuals sunny hours before and at the policy start
        kernel_actuals_policy_time_hours = policy_time_sunny_hours[policy_time_sunny_hours .<= policy_actuals_len];
        policy_actuals_kernel_len = length(kernel_actuals_policy_time_hours);
        policy_lookahead_kernel_len = kernel_scenario_len - policy_actuals_kernel_len;
    else
        policy_lookahead_kernel_len = policy_model_len - 1;
        policy_actuals_kernel_len = scenario_len - policy_lookahead_kernel_len;
    end

    # initialize the matrix for the normal random variables for the calculation of Z
    W = Matrix{Float64}(undef, number_of_scen, kernel_scenario_len);
    # initialize the vector for the cumulative distribution function on Z
    cdf_Z_48 = zeros(scenario_len,1);

    # initialize the matrix for the scenarios
    Y = Matrix{Float64}(undef, number_of_scen, scenario_len);

    Y = Matrix{Float64}(undef, number_of_scen, scenario_len);

    for nscen in 1:number_of_scen
        # nscen = 1
        # initialize
        array_actual_Z = Array{Float64}(undef, kernel_scenario_len)
        array_actual_phi = Array{Float64}(undef, kernel_scenario_len)
    
        # checks
        max_actual = Array{Float64}(undef, kernel_scenario_len)
        min_actual = Array{Float64}(undef, kernel_scenario_len)
        # loop through number of scenarios to get W realizations from actuals
        for k in 1:kernel_scenario_len
            current_marginals_dist = current_marginals[k, percentile_column_index]
            vec_current_marginals_dist = collect(current_marginals_dist)
            ecdf_actuals = ecdf(vec_current_marginals_dist)
    
            actual_lp_via_md = ecdf_actuals(current_marginals[k,:avg_actual])
            if actual_lp_via_md  == 1
                actual_lp_via_md  = 0.99
            elseif actual_lp_via_md  == 0
                actual_lp_via_md  = 0.01
            end
            
            # take inverse
            actual_Z_via_md = quantile(d_norm, actual_lp_via_md)
    
            array_actual_Z[k] = actual_Z_via_md
        end
    
        W_from_actuals = inv(M) * array_actual_Z
    
        # set the historical landing probabilities in the first columns of W
        # W[nscen, 1:policy_actuals_len] = historical_lp; # XXX wrong
        W[nscen, 1:policy_actuals_kernel_len] = W_from_actuals[1:policy_actuals_kernel_len];
    
        # W_upd = rand(d, solar_policy_forecast_length); # policy_forecast_length
        # the rest of the columns are filled with random numbers
        W_upd = rand(d_norm, policy_lookahead_kernel_len); # policy_forecast_length
    
        # W[nscen, solar_policy_actuals_len+1:end] = W_upd; # policy_actuals_len
        W[nscen, policy_actuals_kernel_len+1:end] = W_upd; # policy_actuals_len
    
        W_lookahead = W[nscen, :];
    
        Z = M * W_lookahead;
    
        cdf_Z_base = cdf.(d_norm, Z);
    
        # cdf_Z_48[lookahead_sunny_indices] = cdf_Z; # XXX skip
        if is_solar
            # model_sunny_indices = lookahead_sunny_indices[policy_actuals_len+1:end];
            cdf_Z_48[policy_time_sunny_hours] = cdf_Z_base;
        else
            cdf_Z_48 = cdf_Z_base;
        end
    
        # current_marginals = marginals_by_issue[issue_index];
    
        for k in 1:scenario_len
            # k = 1
            # marginal_id = within_forecast_sunny_hours[k];
            # current_marginals_dist = current_marginals[marginal_id, 3:101];
            current_marginals_dist = current_marginals[k, percentile_column_index];
            current_actual = current_marginals[k, :avg_actual];
            
            # calculate 
            if k <= policy_actuals_kernel_len # replace policy_actuals_len with actual values
                Y[nscen, k] = current_actual;
            else
                Y[nscen, k] = quantile(current_marginals_dist, cdf_Z_48[k]);
            end
        end
    end
    
    model_indices = (scenario_len - policy_model_len + 1): (scenario_len)
    policy_model_Y = Y[:, model_indices];

    return policy_model_Y;
end