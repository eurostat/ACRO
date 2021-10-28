* safe.ado
* Stata implementation of ACRO ('safe SDC' intercession)

* Copyright © European Commission. This software is released under the EUPL version 1.2.
* Acknowledgments: This code was developed as output of a project entitled "Access to European Microdata in Eurostat Safe Centre: Automatic checking of the output" (Specific Contract N° 000058 ESTAT N°2019.0337, under the Framework Contract 2018.0086) by Elizabeth Green, Felix Ritchie and Jim Smith of the University of the West of England, Bristol. 
* For queries contact estat-confidentiality@ec.europa.eu. 

* Created June 2020 by Felix Ritchie and Lizzie Green


*********************************************************************************
* main program code                                                             *
*********************************************************************************
	
capture program drop safe

program safe , byable(onecall) rclass
  syntax anything [if] [in] [fweight  aweight  pweight  iweight] [, *]

		* switch on and off - quietly in normal use, noisily for testing
*		quietly {
  noisily {

		  * first check that set up has been run - NB coding this way allows for not to be set and set to 1/0
		
				if "$ACRO_setup_run"=="ok" {
				
  		  * give friendly name to full command and the stat to be calculated
		  		local command = `"`0'"'
				  if `"`options'"'=="" {
				    local command = `"`command' , "'
  				}
		  		local stat = "`1'"

 			
  				******************************************************************************
	     * parsing stage 1: check for 'by-ness', and if so deal with it
				  * xi is sorted out by stata in call
  	   ******************************************************************************
	     if _by() {
	       * strip the bys 
     	  local by_code = "by `_byvars' : "
  						local sort_code = "sort `_byvars'"
		  		}
				  else {
			     local by_code = ""
  						local sort_code = ""
		  				*** need to do something about xi here ***
      }

  	   ******************************************************************************
    	 * parsing stage 2: check that command exists
	     ******************************************************************************

      scalar graph_commands = "$ACRO_cmds_graph1 $ACRO_cmds_graph2 $ACRO_cmds_twoway1 $ACRO_cmds_twoway2 $ACRO_cmds_twoway3 $ACRO_cmds_twoway4"
      scalar all_commands = "$ACRO_cmds_tabular $ACRO_cmds_estimates_r  $ACRO_cmds_estimates_e $ACRO_cmds_other $ACRO_cmds_double" + graph_commands

  				local exists = strpos(all_commands, "`stat'") > 0
	
	     ******************************************************************************
  	   * parsing stage 3: get the output sheets and other parameters, incl from globals
  	   ******************************************************************************

		   	extract_parameter "output_sheet" `"`options'"'
		    local temp = r(extract)
    		local output_sheet =  subinstr(`"`temp'"', `"""', "", .)
	     if "`output_sheet'" == "." {
				    * no sheet specified
						  local output_sheet = "output_$ACRO_output_num"
  						local command  = `"`command' output_sheet("`output_sheet'")"'
		  				global ACRO_output_num = $ACRO_output_num+1
				  }
      local sheet_opt = `"output_sheet("`output_sheet'")"'
		
		  		extract_parameter "exception" `"`options'"'
	     local temp = r(extract)
    		local exc_text =  subinstr(`"`temp'"', `"""', "", .)
	     if "`exc_text'" == "." {
  		    local exception = ""
						  local exc_opt = "no exception option"
  				}
		  		else {
  		  		local exception = `"exception("`exc_text'")"'
						  local exc_opt = `"exception(`temp')"'
  		  }		

		  		* set up weight if needed
				  local in_weights = ""
  				if "`weight'"!="" {
		  		  local in_weights = "[`weight'`exp']"
				  }
 			
  				local output_file = "$ACRO_out_file"
		 		
	     * suppression, allowing for default and then overrides 
  				local sup_opt = "suppress"
		  		if $ACRO_suppress {
				    local suppress = "suppress"
  				}
		  		else {
				    local suppress = ""
  				}
		  		if strpos(`"`command'"', "nosuppress")>0 {
				    local suppress = ""
						  local sup_opt = "nosuppress"
  				}
		  		else if strpos(`"`command'"', "suppress")>0 {
				    local suppress = "suppress"
  				}
		  		
				  * generate clean version of the command so that we can run if not existing/implemented or a failure
  				local clean_options = subinstr(subinstr(subinstr(`"`options'"',`"`sheet_opt'"',"",.),`"`exc_opt'"',"",.),"`sup_opt'","",.)
		  		local clean_command = subinstr(subinstr(subinstr(`"`command'"',`"`sheet_opt'"',"",.),`"`exc_opt'"',"",.),"`sup_opt'","",.)

			   *****************************************************************************
  				* Now run the command
		  		* if it doesn't exist, isn't implemented, or failed, run the clean command (nothing goes to Excel
				  *****************************************************************************

  	   if `exists' {
  
  						capture erase "$ACRO_temp_results"
		  				global ACRO_by_count = $Char_A
						
  				  if "`stat'" == "table" {
		  					  local temp = subinstr(`"`anything'"', "table ", "", 1)
	         `by_code' safe_table `temp' `if' `in' `in_weights', orig_stat("table") `clean_options' `exception' `suppress' output_sheet("`output_sheet'")
   	    }
		  		  else if ("`stat'" == "tab") |  ("`stat'" == "tabulate") {
				  		  * row/col must be 2nd and 3rd items
						  		tokenize "`anything'"
          `by_code' safe_table `2' `3' `if' `in'  `in_weights' , orig_stat("tabulate") `clean_options' `exception' `suppress' output_sheet("`output_sheet'")
  						}
		  		  else if strpos("$ACRO_cmds_estimates_r $ACRO_cmds_estimates_e", "`stat'") > 0 {
				  		  `by_code' safe_estimates `command'
  						}
		  		  else if strpos(graph_commands, "`stat'") > 0 {
          * graph commands are not byable or can have weights in cmd line
		  				  safe_graph `command'
				  		}
  				  else {
		  				  send_message "[`stat'] not implemented yetxxx"
 			  		  `sort_code'
  						  `by_code' `clean_cmd'
		  				}

				  		* now print full stata output to spreadsheet if either it passes or fails with exception request
						  * note: for some cases (eg regression) where output needs to be produced to get SDC data, we've already done this
  						* if no approved (or if suppressed) then just print to normal output
		  				local result = r(outcome)
						
					  	if (`result' == $ACRO_outcome_p) | (`result' == $ACRO_outcome_f_exception) | (`result' == $ACRO_outcome_f_review) {
						
						    if (`result' == $ACRO_outcome_p) {
    								noisily display "********************************
    								noisily display "*** Output passed SDC checks ***
  		  						noisily display "********************************
						  		}
						    else if (`result' == $ACRO_outcome_f_review) {
  								  noisily display "********************************
    								noisily display "*** Output subject to review ***
    								noisily display "********************************
				  				}
						  		else {
  						  		noisily display "******************************************************
  								  noisily display "*** Output failed SDC checks - exception requested ***
    								noisily display "******************************************************
		  						}
				  		  local first_line = r(rows_written)+2
						  }
  						else {
		  				  * failed/suppressed out - not saved to clearance file
				  		  if (`result' == $ACRO_outcome_f_suppress)  {
  				  				noisily display "******************************************************
  						  		noisily display "*** Output failed SDC checks - suppression applied ***
  								  noisily display "*** Suppressed output only to clearance file       ***
    								noisily display "******************************************************
		  						}
				  				else {
  				  				noisily display "***********************************
  						  		noisily display "*** Output failed SDC checks    ***
  								  noisily display "*** No output to clearance file ***
    								noisily display "***********************************
 	  						}
				  				noisily {
   			  		  `sort_code'
		  				    `by_code' `clean_command'
  								}
		  				}
				  }
  				else {
		  		  noisily {
  		  		  send_message "[`stat'] not recognised for safe review"
 	  		  		`sort_code'
				  		  `by_code' `clean_command'
  						}
		  		}
  				* end exists/not exists
  
    }
				else {
				  send_message "Safe setup not yet run"
				}
				* end test for global safe setup
				
		}
		* end quietly
	
end
* end of program 'safe'
