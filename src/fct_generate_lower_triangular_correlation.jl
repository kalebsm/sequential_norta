function generate_lower_triangular_correlation(covariance_matrix) #,
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
    # # ==================================================================
    # # COLUMNS TO KEEP
    # # ==================================================================
    # #=Here, we care only about the columns in x::DataFrame whose elements 
    # are not all equal. If they are, the correlation is not defined b/c
    # the standard deviation will be zero for columns whose elements
    # are all the same =#
    # x = copy(data)
    # allequal_set = Set(findall(allequal, eachcol(x)));
    # allequal_ind = sort(collect(allequal_set));
    # allindex_set = Set(collect(1:48));
    # alldifferent_ind = sort(collect(setdiff(allindex_set, allequal_set))); # Index for columns whose st. dev. isn't zero
    # x_upd = x[:, alldifferent_ind];


    # ==================================================================
    # CORRELATION MATRIX
    # ==================================================================
    #= Determine a lower-triangular, nonsingular factorization M of the 
        the correlation matrix for Z such that MM' = Sigma_Z. =#

    
    if ishermitian(cor(covariance_matrix))
        Σ_Z = LinearAlgebra.cholesky(cor(covariance_matrix));
    else
        Σ_Z = factorize(cor(covariance_matrix));
    end
    M = Σ_Z.L;

    return M
    
end