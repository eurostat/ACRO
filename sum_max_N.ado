* sum_max_n.ado
* Stata program to sum the maximum N values (needed for dominance checks)

* Copyright © European Commission. This software is released under the EUPL version 1.2.
* Acknowledgments: This code was developed as output of a project entitled "Access to European Microdata in Eurostat Safe Centre: Automatic checking of the output" (Specific Contract N° 000058 ESTAT N°2019.0337, under the Framework Contract 2018.0086) by Elizabeth Green, Felix Ritchie and Jim Smith of the University of the West of England, Bristol. 
* For queries contact estat-confidentiality@ec.europa.eu. 

* V01 created July 2020 by Felix Ritchie
* Last modified:
*  dd.mm.yy vxx who what

* this program calculates the value of the N largest values for a variable (missings counted as zero)
* inputs:
*   varname     name of the variable to check
*   max_n()    (required) number of largest values to retain
*   by()       (optional) do by values listed
*   complement (optional) calculate the N-max_n smallest values, instead of max_N largest
*   absolute   (optional) make all negative values pos after ordering (to esnure dom checks pass)
* returns:
*   new variable ACRO_max_n_varname with only the the max_n largest values non-zero

capture program drop sum_max_n

program sum_max_n 
  syntax varname [if] [in] [, complement absolute *]

		quietly {
    local varname = "`varlist'"
    extract_parameter  "max_n" "`options'"
		  local max_n = r(extract)
    extract_parameter "by" "`options'"
		  local byvars = r(extract)
  		if "`byvars'"=="." {
		    local byvalues = ""
				  local byvars = ""
   	}
		  else {
				  local byvalues = "by `byvars' ACRO_use_here :"
  		}

		  capture drop ACRO_max_n_`varname'
  		capture drop ACRO_use_here
		  if "`if'`in'"=="" {
		    gen ACRO_use_here = 1
  		}
		  else {
		    gen ACRO_use_here = 0
  				replace ACRO_use_here = 1 `if' `in'
		  }
		  gen ACRO_max_n_`varname' = `varname' if ACRO_use_here
  		replace ACRO_max_n_`varname' = 0 if ACRO_max_n_`varname' == . & ACRO_use_here
    sort `byvars' ACRO_use_here ACRO_max_n_`varname'
				if "`absolute'" == "absolute" {
  	 		replace ACRO_max_n_`varname' = abs(ACRO_max_n_`varname') if ACRO_use_here
				}
  		if "`complement'" == "complement" {
    		`byvalues' replace ACRO_max_n_`varname' = 0 if _n>(_N-`max_n') & ACRO_use_here
  		}
		  else {
  		  `byvalues' replace ACRO_max_n_`varname' = 0 if _n<=(_N-`max_n') & ACRO_use_here
  		}
		  drop ACRO_use_here
		}
end

		  
