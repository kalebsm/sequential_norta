function generate_lower_triangular_correlation(data, issue_idcs, dec_mdl_lkd_len, is_solar) #,
    #scenario_hour,
    #scenario_day,
    #scenario_month,
    #scenario_year)

    """
    generate_probability_scenarios: 

    # Arguments:
    - 

    # Returns:
    - 
    """
    # ==================================================================
    # COLUMNS TO KEEP
    # ==================================================================
    #=Here, we care only about the columns in x::DataFrame whose elements 
    are not all equal. If they are, the correlation is not defined b/c
    the standard deviation will be zero for columns whose elements
    are all the same =#
    x = copy(data)
    allequal_set = Set(findall(allequal, eachcol(x)));
    allequal_ind = sort(collect(allequal_set));
    allindex_set = Set(collect(1:48));
    alldifferent_ind = sort(collect(setdiff(allindex_set, allequal_set))); # Index for columns whose st. dev. isn't zero
    x_upd = x[:, alldifferent_ind];


    # ==================================================================
    # CORRELATION MATRIX
    # ==================================================================
    #= Determine a lower-triangular, nonsingular factorization M of the 
        the correlation matrix for Z such that MM' = Sigma_Z. =#

    
    if ishermitian(cor(x_upd))
        Σ_Z = LinearAlgebra.cholesky(cor(x_upd));
    else
        Σ_Z = factorize(cor(x_upd));
    end
    M = Σ_Z.L;


    if is_solar

        # initialize vector for indices of zeros
        solar_zero_indices = Vector{Int64}();

        allequal_ind_1d = allequal_ind[1:length(allequal_ind) ÷ 2];

        # loop through the number issue times
        for i in issue_idcs
            solar_zero_indices = vcat(solar_zero_indices, allequal_ind_1d .+ (i-1)*24)
        end
        # checks of lengths - both are TRUE
        # println(dec_mdl_lkd_len == 363*24+24)
        # println(363*48 == size(corr_forecast_issue_times,1))

        solar_vector = ones(dec_mdl_lkd_len);
        # for idx in solar_zero_indices
        #     solar_vector[idx] = 0
        # end
        solar_vector[solar_zero_indices] .= 0;

        all_decision_hours = Set(collect(1:dec_mdl_lkd_len));
        sunny_decision_hours = sort(collect(setdiff(all_decision_hours, solar_zero_indices)));

        return M, sunny_decision_hours
    else
        return M
    end
    
end