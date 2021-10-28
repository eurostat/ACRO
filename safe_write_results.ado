* safe_write_results.ado
* Created August 2020 by Felix
* code to write results currenlty in memory ACRO safe outputs to spreadsheet

* Copyright © European Commission. This software is released under the EUPL version 1.2.
* Acknowledgments: This code was developed as output of a project entitled "Access to European Microdata in Eurostat Safe Centre: Automatic checking of the output" (Specific Contract N° 000058 ESTAT N°2019.0337, under the Framework Contract 2018.0086) by Elizabeth Green, Felix Ritchie and Jim Smith of the University of the West of England, Bristol. 
* For queries contact estat-confidentiality@ec.europa.eu. 


* This program writes
*   the orginal command
*   whether the output was approved or not
*   if it failed and exception was requested, teh reason
*   if approved or an excption requested, the table in momery
*   if failed, a warning message
* Parameters:
*   in_cmd        the original command that generaed the outputs
*   success    whether teh commnd succedded or not
*   out_file   name of file to save/create
*   sheetname  name o fworksheet to create
*   exception  (optional) reason for requesting an exception
* Note: the existing spreadsheet with that name is replaced
* Note: parameters are in quotes

capture program drop safe_write_results

program define safe_write_results , rclass
  args in_cmd success out_file sheetname exception no_print

  quietly {
*		noisily {

  		preserve 
		  local ok_to_print = (`success' != $ACRO_outcome_f)
		  clear
		  local written = 6
		  set obs `written'

 	  gen text = "Rules applied: $ACRO_dataset" if _n==1
 	  replace text = `"`in_cmd'"' if _n==2
    replace text = "Outcome: ${ACRO_outcome_label`success'}"  if _n==3
    replace text = `"${ACRO_outcome_label`success'} Justification: `exception'"'  if (_n==3) & (`success'==$ACRO_outcome_f_exception)
    replace text = " "  if _n>3

		  if `ok_to_print' {
		    replace text = "ACRO cleared output:"  if _n==6
				}
				else {
		    replace text = "*** no output cleared ***"  if _n==6
  		}
				
		  export excel using "`out_file'", sheet(`sheetname') sheetreplace cell(a1)
  		putexcel set "`out_file'" , sheet("`sheetname'") modify 
    putexcel A4 = formula(`"=+HYPERLINK("[$ACRO_out_name]description!A1","Back to description page")"')
    putexcel A4, font(calibri, 11, red) bold underline
				
		  restore

    if (`ok_to_print'==1) & ("`no_print'"!="no_print"){		
						export excel using "`out_file'", sheet(`sheetname') sheetmodify cell(a7) firstrow(variables) missing("n/a")
		  		local written = 8 + _N 
    }

		  return local rows_written = `written'

  }
		* end quietly/noisily 
		
end
