* safe_table
* program to test a one or two-way table for disclosure risk, and suppress if necessary add requested
* Created July 2020 by Felix Ritchie and Lizzie Green

* Copyright © European Commission. This software is released under the EUPL version 1.2.
* Acknowledgments: This code was developed as output of a project entitled "Access to European Microdata in Eurostat Safe Centre: Automatic checking of the output" (Specific Contract N° 000058 ESTAT N°2019.0337, under the Framework Contract 2018.0086) by Elizabeth Green, Felix Ritchie and Jim Smith of the University of the West of England, Bristol. 
* For queries contact estat-confidentiality@ec.europa.eu. 

* changes from the standard 'table' command:
*   command 'table'       omitted
*   option `supress'      whether to suppress uncecceptable values
*   option 'exception( )' allow for exception to be requested in case of failure
*   option no_write       don't write results to spreadsheet (for when this prog is being used by other internal calculations)
*   outsheet(nn)          specifies output sheet nn
* globals:
*   SDC parameters        (system manager set)
*   ACRO_out_file         Output_file name (set by user in safe_setup
* returns:
*   outcome	              coded outcome
*   clean_cmd             cleaned command string
*   rows_written          n rows written to output spreadsheet
* Note: exception and outsheet may have quote marks eg outsheet("this_one") - these are removed
* Note: this program adds results to $ACRO_temp_results - make sure the file is empty 
* BEFORE running (can't do things entirely in here because the command might be 'byed'  

capture program drop safe_table 

program define safe_table ,  rclass byable(recall, noheader) 
  syntax varlist(min=1 max=2) [if] [in] [fweight  aweight  pweight  iweight] [, suppress no_write *]
  marksample touse , strok

* switch on and off - quietly in normal use, noisily for testing
  quietly {
*  noisily {
	
	   * prep - delete temp file
  		* stage 1: extract paramater values and settings
   	******************************************************************************

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

				* set up weight if needed
				local weights = ""
				if "`weight'"!="" {
				  local weights = "[`weight'`exp']"
				}

  		* get additional parameters specific to safe_table - remove this from the standard 'options' list
		  extract_parameter "exception" `"`options'"'
  		local temp = r(extract)
    local no_exception = `"`temp'"' == "."
		  local exception = subinstr(`"`temp'"', `"""', "", .)
	   local options = subinstr(`"`options'"', `"exception("`exception'")"', "", .)
				
				extract_parameter "output_sheet" `"`options'"'
		  local temp = r(extract)
  		local output_sheet =  subinstr(`"`temp'"', `"""', "", .)
				local options = subinstr(`"`options'"', `"output_sheet("`output_sheet'")"', "", .)
				
				local suppressing = "`suppress'" == "suppress"
				local options = subinstr(`"`options'"', `"suppress"', "", .)
				local no_write= "`no_write'" == "no_write"
				local options = subinstr(`"`options'"', `"no_write"', "", .)
				
		  extract_parameter "orig_stat" `"`options'"'
  		local temp = r(extract)
		  local orig_stat = subinstr(`"`temp'"', `"""', "", .)
	   local options = subinstr(`"`options'"', `"orig_stat("`orig_stat'")"', "", .)

    if "`_byvars'" !="" {
		    local output_sheet = "`output_sheet'_" + char($ACRO_by_count)
						global ACRO_by_count = $ACRO_by_count + 1
  		} 

  		* find number of variables - need to allow for super-rows
    tokenize "`varlist'"
  		local row_var = "`1'"
		  local col_var = "`2'"
  		local row_vars=1
		  local extra_rows = ""

  		extract_parameter "by" `"`options'"'
  		local temp = r(extract)
		  if "`temp'"=="." {
		    local bystring = ""
  		}
		  else {
  		  tokenize "`temp'"
      while "``row_vars''" !="" {
        local super_rows = "`super_rows' ``row_vars''"
  		    local row_vars = `row_vars' + 1
  		  }
	     local bystring = "by(`temp')"
  		}
		  * this is what we will use to index the temp file
  		local index_field = "`row_var' `col_var' `super_rows'"
			
	   * finally: get the vars and stats to be noisily displayed
  		* always generate freq
  		extract_parameter "contents" `"`options'"'
  		local stat_list = r(extract)
  		local freq_only = ("`stat_list'" == ".") | ("`stat_list'" == "freq") 
    local stat1 = "freq"
    local num_stats = 1
  		if !`freq_only' {
		    tokenize "`stat_list'"
    		local item = 1
		    while "``item''" != "" {
        if "``item''" == "freq" {
		  				  * ignore - already got it as first var
				  		}
						  else {
  				    local num_stats = `num_stats' + 1
  		      local stat`num_stats' = "``item''"
        		local item = `item'+1
				      local var`num_stats' = "``item''"
  				  }
      		local item = `item'+1
		  		}
    }				

  		* now go through and do each stat requested, saving in the temp file
				* Note: no weights used in this stage

		  tempfile results
				
		  forvalues statn = 1/`num_stats' {

				  preserve
      if `statn'==1 {
    		  * frequency
				  		table `row_var' `col_var' if `touse' , `bystring' contents(freq) replace
  				  ren table1 frequency
    	  	forvalues nn = 1/`num_byvars' {
          `by_gen`nn''
  	     }
      }
		  		else {
				    * first get top N obs as % of total
						  local full_byset = "`row_var' `col_var' `super_rows'"
  						bysort `full_byset' `touse': egen ACRO_tot`var`statn'' = total(`var`statn'')
    				sum_max_n `var`statn'' if `touse', max_n($ACRO_nk_n)   
        ren ACRO_max_n_`var`statn'' ACRO_nk_n_`var`statn'' 
        replace ACRO_nk_n_`var`statn'' = ACRO_nk_n_`var`statn'' / ACRO_tot`var`statn'' 
		  				* now get sum of smallest N-2 obs
				    sum_max_n `var`statn'' if `touse', max_n(2) complement 
        ren ACRO_max_n_`var`statn'' ACRO_pratio_`var`statn''
						
    		  table `row_var' `col_var' if `touse' , `bystring' contents(count `var`statn'' max `var`statn'' rawsum ACRO_nk_n_`var`statn'' rawsum ACRO_pratio_`var`statn'' `stat`statn'' `var`statn'') replace
  		  		ren table1 freq_`statn'_`var`statn''
  				  ren table2 max_`statn'_`var`statn''
    				ren table3 sum_nk_`statn'_`var`statn''
    				ren table4 sum_p_`statn'_`var`statn''
		    		ren table5 `stat`statn''_`var`statn''
  	  	  forvalues nn = 1/`num_byvars' {
          `by_gen`nn''
  	     }
		  		  merge 1:1 `index_field' using `results' , nogenerate
				  }
  		  save `results' , replace
		  		restore
    }	 
				* end of loop to create results matrix

  		* so, at this point, we have a 'dataset' which contains all the results in the form
		  *   [by variables] freq count1 max1 nk%1 pratio1 stat1... countn maxn nk%n pration statn
		  * we need to go through each stat and check that it meets threshold and dominance criteria
		  * we will build up list of problems; if suppress is "on" we'll delee a we go
  		* remember, we have the number of stats held in macros 

				* NB this could be more efficient - don't create daa for checks if we're not going to do them - for later
				
				preserve 
				
				use `results', clear
				
    foreach vv in count dof maxmin dom {
  		  gen check_`vv'_overall = 0
		    gen check_`vv' = 0
    }
    forvalues statn = 1/`num_stats' {
      foreach vv in count dof maxmin dom {
  		    replace check_`vv' = 0
      }
      if `statn'==1 {
    		  * frequency
								replace check_count = 0
        if strpos("$ACRO_tests","threshold")>0 {
		    		  replace check_count = 1 if frequency < $ACRO_threshold
 								}
						}
      else {
						  if ("`stat`statn''"=="count") | ("`stat`statn''"=="n") {
    		    * frequency of specific var
										replace check_count = 0
										if strpos("$ACRO_tests","threshold")>0 {
    		    		replace check_count = (freq_`statn'_`var`statn'' < $ACRO_threshold)
										}
        }
        else if ("`stat`statn''"=="sd") | (substr("`stat`statn''",1,2)=="se") {
    		    * safe stats - just check enough dofs
  		    		replace check_dof = (freq_`statn'_`var`statn''-1) < $ACRO_dof_threshold
        }
        else if ("`stat`statn''"=="max") | ("`stat`statn''"=="min") {
								  /* don't think we need this...
          if strpos("$ACRO_tests","threshold")>0 {
   	    		  replace check_count = (freq_`statn'_`var`statn'' < $ACRO_threshold)
							   }
					  			else {
										  replace check_count = 0
	  							}
										*/
		    		  replace check_maxmin = 0 
										if strpos("$ACRO_tests","maxmin")>0 {
    		      * max/min not allowed
		    		    replace check_maxmin = 1 
							   }
	       }
      		else {
      		  * check for freq and dom in remainder of stats
    		    replace check_dom = 0 
			       if strpos("$ACRO_tests","nk")>0 {
  				  				replace check_dom = check_dom + (sum_nk_`statn'_`var`statn'' > $ACRO_nk_k)
										}
			       if strpos("$ACRO_tests","pratio")>0 {
										  replace check_dom = check_dom + ((sum_p_`statn'_`var`statn''/max_`statn'_`var`statn'')<=$ACRO_pratio_p)*2
										}
  				  }
						}
		  		* end of ifs for type of command

				  * now remove calculation columns, suppress values if relevant
						if `statn' == 1 {
  				  * frequency
				  		if ("`suppress'"=="suppress") & `no_exception' {
						  		replace frequency = . if check_count==1
				    }				
  				}
		  		else {
        drop max_`statn'_`var`statn'' sum_nk_`statn'_`var`statn'' sum_p_`statn'_`var`statn'' 
        if ("`suppress'"=="suppress") & `no_exception' {
          replace freq_`statn'_`var`statn'' = . if check_count==1
  								replace `stat`statn''_`var`statn'' = . if (check_dof+check_maxmin+check_dom+check_count)>0
  		    }				
		  		}
	     foreach vv in count dof maxmin dom {
    		  replace check_`vv'_overall = check_`vv'_overall + check_`vv'
      }
    }	
  		* end of loop to check/clean up stats

		  * and now tidy up and write problem text and summary
	   foreach vv in count dof maxmin dom {
  		  egen any_`vv' = max(check_`vv'_overall)
		  		scalar probs_`vv' = any_`vv'[1]>0
				  drop any_`vv'
    }				
    gen str1 problems = ""
		  replace problems = "below threshold; " if check_count_overall
    replace problems = problems + "too few DoFs; " if check_dof_overall 
    replace problems = problems + "max/min not allowed; " if check_maxmin_overall
		  replace problems = problems + "dominance; " if check_dom_overall
    replace problems = "ok" if problems==""

				local outcome = $ACRO_outcome_p
    if (probs_count + probs_maxmin + probs_dof +probs_dom)>0 {
				  if `no_exception' {
				    if ("`suppress'"=="suppress") { 
    				  local outcome = $ACRO_outcome_f_suppress
  						}
    				else {
          local outcome = $ACRO_outcome_f
				    }
						}
						else {
  				  local outcome = $ACRO_outcome_f_exception
						}
				}

	 		if `"`exception'"'=="." {
		    local exception = ""
				}

				if "`no_write'"=="no_write" {
				  local temp = 0
				}
				else {
				  drop check_count* check_dom* check_dof* check_max*
      order `row_var' `col_var' `super_rows' frequency , first
  				order problems , last
     	noisily safe_write_results `"`orig_stat' `row_var' `col_var' `if' `in' `weights' , `options' `byvalues'"' `outcome' `"$ACRO_out_file"' `"`output_sheet'"' `"`exception'"'
      local temp = r(rows_written)
    }
    return scalar outcome = `outcome'
		  return scalar rows_written = `temp'
				
				restore

				* add weights back in here
				if (`outcome'==$ACRO_outcome_p)  | (`outcome'==$ACRO_outcome_f_exception) {
  				noisily dump_output `"`orig_stat' `row_var' `col_var' if `touse' `in' `weights', `options'"' "$ACRO_out_file" "`output_sheet'" A `temp' "$ACRO_temp_log"
    }
				noisily safe_write_index `"`output_sheet'"' "unsafe statistic: `orig_stat'" `outcome' `"`exception'"'
				
  }
		* end quietly/noisily 
		
end
