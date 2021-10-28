* get_values.ado
* Stata program to extract the uniques values of categorical variables

* Copyright © European Commission. This software is released under the EUPL version 1.2.
* Acknowledgments: This code was developed as output of a project entitled "Access to European Microdata in Eurostat Safe Centre: Automatic checking of the output" (Specific Contract N° 000058 ESTAT N°2019.0337, under the Framework Contract 2018.0086) by Elizabeth Green, Felix Ritchie and Jim Smith of the University of the West of England, Bristol. 
* For queries contact estat-confidentiality@ec.europa.eu. 

* V01 created July 2020 by Felix Ritchie
* Last modified:
*  dd.mm.yy vxx who what

capture program drop get_values

program get_values, rclass
  * program to get each of the distinct values from a variable
		* checks up to 20 values to determine if categorical var or not

  preserve
		capture tostring `0', replace
		sort `0'
		by `0': gen double `0'xxn = _N
	 scalar uniques = ""
		local checking = 1
  local current = 1
		
	 while `checking'==1 {
    scalar uniques = uniques + " " + `0'[`current']
				local current = `current'+`0'xxn[`current']
				if `current'>_N {
				  local checking = 0
				}
				display "Checking: `checking' value: " uniques
  }
		restore
  return local uniques_`0' = uniques
end
* end of get_values

		
