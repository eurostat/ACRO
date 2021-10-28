* dump_output.ado
* Stata program to dump the text output from a stata command into an Excel file

* Copyright © European Commission. This software is released under the EUPL version 1.2.
* Acknowledgments: This code was developed as output of a project entitled "Access to European Microdata in Eurostat Safe Centre: Automatic checking of the output" (Specific Contract N° 000058 ESTAT N°2019.0337, under the Framework Contract 2018.0086) by Elizabeth Green, Felix Ritchie and Jim Smith of the University of the West of England, Bristol. 
* For queries contact estat-confidentiality@ec.europa.eu. 

* V01 created July 2020 by Felix Ritchie
* Last modified:
*  dd.mm.yy vxx who what

* Note: You need to have the calling code running 'noisily'

capture program drop dump_output

program define dump_output, byable(onecall) rclass
  args in_cmd output_file output_sheet output_col output_row temp_log_file table dofs

 	quietly {
*		noisily {
		
	   if _by() {
	     * strip the bys 
     	local by_code = "by `_byvars' : "
						local sort_code = "sort `_byvars'"
				}
				else {
			   local by_code = ""
						local sort_code = ""
	   }
	
		  * run the command, saving to text file
				capture log close ACRO_temp
				matrix results = 0
				log using "`temp_log_file'" , replace name(ACRO_temp) text
				set linesize 255
				`sort_code'
    noisily {
				  display "ACRO validated output"
		     `by_code' `in_cmd'
	   			if "`dofs'"!="" {
  				  local rdof = `dofs'
								return scalar r_dof= `rdof'
  				}
	
						if "`table'" =="table" {
			  	  matrix results = r(table)
						}
				}
    log close ACRO_temp
    return matrix out_table = results

				* now load as a plain text - vars should be listed as v1
				preserve
				import delimited "`temp_log_file'", delimiter("zxxczx", asstring) varnames(nonames) clear
	
    gen cmdline = 0
				replace cmdline = _n if v1 == "ACRO validated output"		
				egen firstline = max(cmdline)	
				drop if _n < firstline
				drop firstline cmdline
				export excel using "`output_file'", sheet("`output_sheet'") sheetmodify cell("`output_col'`output_row'") 
    return scalar lines_written = _N
				
				* change to Courier font so it looks better
	 		putexcel set "`output_file'" , sheet("`output_sheet'") modify 
				local last_row = `output_row'+_N
    putexcel `output_col'`output_row':`output_col'`last_row', font(courier, 11)
				restore	
				
		}
		* end quietly
		
end

		  
