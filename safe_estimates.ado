* safe_estimates
* program to carry out disclosure risk on estimates and publish the results


* Copyright © European Commission. This software is released under the EUPL version 1.2.
* Acknowledgments: This code was developed as output of a project entitled "Access to European Microdata in Eurostat Safe Centre: Automatic checking of the output" (Specific Contract N° 000058 ESTAT N°2019.0337, under the Framework Contract 2018.0086) by Elizabeth Green, Felix Ritchie and Jim Smith of the University of the West of England, Bristol. 
* For queries contact estat-confidentiality@ec.europa.eu. 

* Created September 2020 by Felix & Lizzie

* Additional options compared to standard command:
*   outsheet(nn)          specifies output sheet nn
* globals:
*   SDC parameters        (system manager set)
*   ACRO_by_num           used to index sheets if by values used
*   ACRO_out_file         Output_file name (set by user in safe_setup
* returns:
*   outcome	              coded outcome
*   clean_cmd             cleaned command string
*   rows_written          n rows written to output spreadsheet
* Note: exception and outsheet may have quote marks eg outsheet("this_one") - these are removed
* Note: if the command is byed, then each estimate is sent to a separate spreadsheet using the global variable ACRO_by_count


capture program drop safe_estimates 

program define safe_estimates ,  rclass byable(recall, noheader) 
  syntax anything [if] [in] [fweight  aweight  pweight  iweight] [, *]
  marksample touse , strok

* switch on and off - quietly in normal use, noisily for testing
  quietly {
*  noisily {
	
  		* stage 1: extract paramater values and settings
  		******************************************************************************

		  local cmd_type = "safe statistic: `1'"
				
    * first, extract the 'by' value currently being used, plus generate text for output file
		  local num_byvars = 0
    if "`_byvars'" =="" {
		    local byvalues = ""
  		}
		  else {
  		  sort `touse'
  		  local byvalues = "By `_byvars': "
		    foreach vv of varlist `_byvars' {
						  capture confirm numeric variable `vv'
    				if _rc==0 {
      		  local temp = string(`vv'[_N])
				    }
  				  else {
		        local temp = `vv'[_N]
  				  }
				  		local byvalues = `"`byvalues' [`vv'=`temp']"'
  				}
		  }

  		* get additional parameters specific to safe_estimates - remove this from the standard 'options' list
				extract_parameter "output_sheet" `"`options'"'
		  local temp = r(extract)
  		local output_sheet =  subinstr(`"`temp'"', `"""', "", .)
				local options = subinstr(`"`options'"', `"output_sheet("`output_sheet'")"', "", .)
    if "`_byvars'" !="" {
		    local output_sheet = "`output_sheet'_" + char($ACRO_by_count)
						global ACRO_by_count = $ACRO_by_count + 1
  		} 

				* finally, where to place outputs in the Excel sheet - -how much space should be left for the summary and the clean table unless just doing tests:
				if "`1'"=="test" | "`1'"=="ttest" {
						local first_line = 7
						local table = "notable"
						local dofs = "r(df_t)"
				}
				else {
						local first_line = 7+12
						local table = "table"
				}

  		* stage 2: run the command (we need to do this first to get DoFs)- we'll need to do in two goes as we need e() and r() results
				******************************************************************************************************************************

				* first, write the results as if they are okay - doing this creates a new sheet for dump_ouput to fill
				* NB if not allowed for estimation tests
				local clean_cmd = `"`anything'"'
				if "`1'"=="test" {
				  local full_cmd = `"`anything'"'
						local dofs = "r(df_r)"
				}
				else {
				  local full_cmd = `"`anything' if `touse'"'
				}
				
				if "`if'"!="" {
  				local clean_cmd = `"`clean_cmd' if `if'"'
				}
				if "`in'"!="" {
  				local clean_cmd = `"`clean_cmd' in `in'"'
				}
				if "`byvalues'"!="" {
  				local clean_cmd = `"`clean_cmd' `byvalues'"'
				}
				if "`weight'"!="" {
  				local clean_cmd = `"`clean_cmd' [`weight'`exp']"'
  				local full_cmd = `"`full_cmd' [`weight'`exp']"'
				}
    safe_write_results `"`clean_cmd'"' $ACRO_outcome_p "$ACRO_out_file" "`output_sheet'" "no exception" no_print
    noisily {
						dump_output `"`full_cmd' , `options'"' "$ACRO_out_file" "`output_sheet'" A `first_line' "$ACRO_temp_log" `table' "`dofs'"
 			}
				if "`1'"=="test" | "`1'"=="ttest" {
   			matrix results= 0
		  		local dofs = r(r_dof)
						local show_matrix = 0
				}
				else {
  				matrix results= r(out_table)
		  		local dofs = e(df_r)
						local show_matrix = 1
				}
				if `dofs'<$safe_dof_threshold {
				  * failure - remove published output
      safe_write_results `"`clean_cmd'"' $ACRO_outcome_f "$ACRO_out_file" "`output_sheet'" 
						return scalar outcome = $ACRO_outcome_f
						noisily safe_write_index `"`output_sheet'"' "`cmd_type'" $ACRO_outcome_f ""
				}
				else {
				  * success - print summary table if regression
						if `show_matrix' {
        putexcel set "$ACRO_out_file" , sheet("`output_sheet'") modify 
						  putexcel A5 = matrix(results), names nformat(number_d2)
						}
						return scalar outcome = $ACRO_outcome_p
						noisily safe_write_index `"`output_sheet'"' "`cmd_type'" $ACRO_outcome_p ""
				}
				* end if check for sufficient degrees of freedom
		}
		* end quietly/noisily 
		
end
