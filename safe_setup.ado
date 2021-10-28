* safe_setup.ado
* Stata implementation of ACRO ('safe SDC' intercession)
* Created June 2020 by Felix Ritchie and Lizzie Green

* Copyright © European Commission. This software is released under the EUPL version 1.2.
* Acknowledgments: This code was developed as output of a project entitled "Access to European Microdata in Eurostat Safe Centre: Automatic checking of the output" (Specific Contract N° 000058 ESTAT N°2019.0337, under the Framework Contract 2018.0086) by Elizabeth Green, Felix Ritchie and Jim Smith of the University of the West of England, Bristol. 
* For queries contact estat-confidentiality@ec.europa.eu. 


* This program sets up the global macros, and allow the user to set up his or her own file location etc 

capture program drop safe_setup

program define safe_setup , rclass
  args working_folder dataset res_file suppress
		
		quietly {
		

    **************************************************************************
    * program code safe_setup                                                *
    **************************************************************************

    safe_globals
				
				global ACRO_setup_run = "ok"
				
  		global ACRO_res_folder = "`working_folder'"

				global ACRO_out_name = "`res_file'.xlsm"
  		global ACRO_out_file = "$ACRO_res_folder\\$ACRO_out_name"
    global ACRO_dataset = strupper("`dataset'")

    global ACRO_suppress = "`suppress'"=="suppress"

				global ACRO_output_num = 1
				
				* set up SDC parameters, dataset-specific if they exist
				local default_SDC = strpos("$safe_SDC_variations", "$ACRO_dataset")== 0
				foreach par in threshold dof_threshold nk_n nk_k pratio_p tests {
  		  if (`default_SDC') | "${safe_`par'$ACRO_dataset}" == "" {
  		    global ACRO_`par' = "${safe_`par'}"
						}
						else {
		      global ACRO_`par' = "${safe_`par'$ACRO_dataset}"
  				}
				}
				if `default_SDC' {
  				global ACRO_dataset = "$safe_SDC_set"
				}
				
    * create the macros and blank files for the spreadsheet
				foreach nn in temp_results temp_image temp_index temp_log{
				  global ACRO_`nn' = "$ACRO_res_folder\\${ACRO_`nn'_file}"
				}
				capture erase "$ACRO_temp_index"
				noisily copy "$ACRO_output_template_file" "$ACRO_out_file" , replace
				
				noisily send_message "Output file is $ACRO_out_file"
				noisily display "*** SDC parameters: ($ACRO_dataset)"
				foreach par in threshold dof_threshold nk_n nk_k pratio_p tests {
	 		  if (`default_SDC') | "${safe_`par'$ACRO_dataset}" == "" {
  		    noisily display "*** `par' = ${ACRO_`par'} (default)"
				  }
						else {
  		    noisily display "*** `par' = ${ACRO_`par'} ($ACRO_dataset)"
  				}
				}			
		}
		* end quietly
		
end
* end of program 'safe'
