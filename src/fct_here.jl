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
        dir = dirname(@__FILE__)
        src_path = joinpath(dir, "..")
        return src_path
end

