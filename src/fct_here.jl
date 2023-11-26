#= Function HERE
========================================================================
Take a path 

--- Input:
        path: strings to directory and/or file. The root directory is 
              the directory of the directory /src
--- Output:
        string with full desired path name.
=======================================================================#

function here(path...)
    root_dir = "g:\\My Drive\\_PhD\\projects\\2021_08_michigan_project_modularNuclearReactors\\ARPA-E_perform_data\\arpa_e_perform_data\\copulas"
    joinpath(root_dir, path...)
end

