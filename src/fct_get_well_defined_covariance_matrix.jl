function get_well_defined_covariance_matrix(lp_df)

    # Organize actual_avg so that every 48 hours are in a row,
    # and each row repeats the previous second half of the previous row, except the first row.
    # There will be 363 rows.

    # matrix = zeros(363, 48)
    # for i in 1:363
    #     if i == 1
    #         matrix[i, :] .= dec_ts[1:48, :avg_actual]
    #     else
    #         matrix[i, 1:24] .= matrix[i-1, 25:48]
    #         matrix[i, 25:48] .= dec_ts[(24*(i-1) + 1):(24*i), :avg_actual]
    #     end
    # end

    # # ==================================================================
    # # COLUMNS TO KEEP
    # # ==================================================================
    # #=Here, we care only about the columns in x::DataFrame whose elements 
    # are not all equal. If they are, the correlation is not defined b/c
    # the standard deviation will be zero for columns whose elements
    # are all the same =#

    x = copy(lp_df)
    allequal_set = Set(findall(allequal, eachcol(x)));
    allequal_ind = sort(collect(allequal_set));
    allindex_set = Set(collect(1:48));
    alldifferent_ind = sort(collect(setdiff(allindex_set, allequal_set))); # Index for columns whose st. dev. isn't zero
    x_upd = x[:, alldifferent_ind];

    # # get the columns of lp_df that are not allequal_ind
    # lp_upd = lp_df[:, alldifferent_ind]

    return x_upd , alldifferent_ind

end 