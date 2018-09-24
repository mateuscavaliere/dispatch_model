

#-------------------------------------------
#----           Defining paths          ----
#-------------------------------------------

ROOT = joinpath(dirname(@__FILE__),"..")

const PATH_SRC  = joinpath( ROOT , "src" )

const TYPES     = joinpath( PATH_SRC , "types.jl"     )
const FUNCTIONS = joinpath( PATH_SRC , "functions.jl" )

#-------------------------------------------
#----       Loading other modules       ----
#-------------------------------------------

include( TYPES     )
include( FUNCTIONS )

#-------------------------------------------
#----        Running main module        ----
#-------------------------------------------

PATH_CASE = get_paths( PATH_SRC );

CASE , GENCOS , DEMANDS , CIRCUITS , BUSES = read_data_base( PATH_CASE )