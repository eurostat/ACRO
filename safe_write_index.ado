* safe_write_index.ado
* Stata program to update the index for the Excel file

* Copyright © European Commission. This software is released under the EUPL version 1.2.
* Acknowledgments: This code was developed as output of a project entitled "Access to European Microdata in Eurostat Safe Centre: Automatic checking of the output" (Specific Contract N° 000058 ESTAT N°2019.0337, under the Framework Contract 2018.0086) by Elizabeth Green, Felix Ritchie and Jim Smith of the University of the West of England, Bristol. 
* For queries contact estat-confidentiality@ec.europa.eu. 

* V01 created September 2020 by Felix Ritchie
* Last modified:
*  dd.mm.yy vxx who what

* the code updates the index file specified in 'safe_setup'

capture program drop safe_write_index

program define safe_write_index, rclass
  args sheetname cmd_type decision exception

		quietly {
*		noisily {
		
    preserve

		  * first create our new entry
				clear
				set obs 1
 			gen sheet = "`sheetname'"
				gen reason = `decision'
				label define outcome_label $ACRO_outcome_labels
				label values reason outcome_label
				gen decision = "ok"
				replace decision = "fail" if reason == ($ACRO_outcome_f) |(reason == $ACRO_outcome_f_dof) 
				replace decision = "review" if (reason == $ACRO_outcome_f_exception) |(reason == $ACRO_outcome_f_review) 
				gen desc = "`cmd_type'"
				gen exc = `"`exception'"'
				replace exc = "n/a" if "`exception'" ==""
				gen final = decision if decision != "review"
	
				* now add to list - use merge because we might overwrite sheets
				capture merge 1:1 sheet using  "$ACRO_temp_index" , nogenerate
				order sheet decision final desc reason exc
				save "$ACRO_temp_index" , replace 
				
		  restore
		}
		* end quietly
		
end

		  
