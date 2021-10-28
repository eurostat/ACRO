* safe_parameters.ado
* Stata implementation of ACRO ('safe SDC' intercession)
* Created September 2020 by Felix Ritchie and Lizzie Green
* This program displays the set up for SDC

* Copyright © European Commission. This software is released under the EUPL version 1.2.
* Acknowledgments: This code was developed as output of a project entitled "Access to European Microdata in Eurostat Safe Centre: Automatic checking of the output" (Specific Contract N° 000058 ESTAT N°2019.0337, under the Framework Contract 2018.0086) by Elizabeth Green, Felix Ritchie and Jim Smith of the University of the West of England, Bristol. 
* For queries contact estat-confidentiality@ec.europa.eu. 



capture program drop safe_show_SDC_parameters

program define safe_show_SDC_parameters , rclass
  args	dataset
		
		if (strupper("`dataset'")=="DEFAULT") | ("`dataset'"=="") {
		  local dataset_name = "default"
				local dataset = ""
		}
  else {
  		local dataset = strupper("`dataset'")
				local found = 0
				foreach nn in $safe_SDC_variations {
				  if "`nn'"=="`dataset'" {
						  local found = 1
						}
				}
		  if `found'==0 {
		    send_message "No specific rules for dataset [`dataset'] - reporting default rules"
				  local dataset= ""
      local dataset_name = "default"		
		  }
				else {
      local dataset_name = "`dataset'"		
				}
		}
				
  noisily display "*********************************************************"
  noisily display "SDC parameters for dataset [`dataset_name']"
  noisily display "*********************************************************"
		
	 noisily display "Threshold for descriptive statistics: ${safe_threshold`dataset'}"
	 noisily display "Threshold for degrees of freedom:     ${safe_dof_threshold`dataset'}"
	 noisily display "Dominance (n, k model):               ${safe_nk_n`dataset'} largest units contribute no more than ${safe_nk_k`dataset'} of the total"
	 noisily display "Dominance (p-ratio model):            N-3 smallest units account for at least ${safe_pratio_p`dataset'} of the largest unit"
  noisily display "SDC rules being applied:              ${safe_tests`dataset'}"	
		
end
* end of program
