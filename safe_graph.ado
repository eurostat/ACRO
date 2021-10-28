* safe_graphs
* program to carry out disclosure risk on graphs
* Because graphs can't be assessed automtically, this progrma simply saves the image,
* uploads it the Excel output sheet and leaves a note for it to be 'reviewed'

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
*   ACRO_temp_image       Temp file to hold PNG graphic file
* returns:
*   outcome	              coded outcome (always "review required")
* Note: graph is not 'byable' - by() is specified in options

capture program drop safe_graph 

program define safe_graph ,  rclass 
  syntax anything [if] [in] [, *]
  marksample touse , strok

  * switch on and off - quietly in normal use, noisily for testing
  quietly {
*  noisily {
	
  		* stage 1: extract paramater values and settings
  		******************************************************************************
				local stat = "`1'"
				local sub_stat = "`2'"
				if "` stat'" == "graph" {
				 	local stat = "`2'"
  				local sub_stat = "`3'"
					}
				local full_type = "`stat'"
		  if "` stat'" == "twoway" {
				 	local full_type = "`stat' `sub_stat'"
				}
		  local cmd_type = "graph: `full_type'"

  		* get additional parameters specific to safe_estimates - remove this from the standard 'options' list
				extract_parameter "output_sheet" `"`options'"'
		  local temp = r(extract)
  		local output_sheet =  subinstr(`"`temp'"', `"""', "", .)
				local clean_cmd = subinstr(`"`0'"', `"output_sheet(`temp')"', "", .)

				* finally, where to place outputs in the Excel sheet - -how much space should be left for the summary and the clean tble:
				local first_line = 5

  		* stage 2: run the command 
				******************************************************************************************************************************

    safe_write_results `"`clean_cmd'"' $ACRO_outcome_f_review "$ACRO_out_file" "`output_sheet'" "no exception" no_print
				`clean_cmd' 
				graph export "$ACRO_temp_image" , replace
  		putexcel set "$ACRO_out_file" , sheet("`output_sheet'") modify 
    putexcel A5 = picture("$ACRO_temp_image")
				capture erase "$ACRO_temp_image"
				return scalar outcome = $ACRO_outcome_f_review
				return local desc = "`cmd_type'"
				noisily safe_write_index `"`output_sheet'"' "`cmd_type'" $ACRO_outcome_f_review " "

		}
		* end quietly/noisily 
		
end
