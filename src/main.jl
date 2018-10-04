#       ------------------------------------------------
#                        Dispatch Model 
#       ------------------------------------------------

#- Author: Jairo Terra, Guilherme Machado, Mateus Cavaliere ( PUC - 2018 )
#- Description: This is the main module of the dispatch model created to emulate a thermal system optimal dispatch

#-----------------------------------------
#----           Loading libs          ----
#-----------------------------------------

using JuMP
using Cbc
using Combinatorics

#-------------------------------------------
#----           Defining paths          ----
#-------------------------------------------

ROOT = joinpath(dirname(@__FILE__),"..")
# ROOT = joinpath(pwd(),"..")

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

main( PATH_SRC )