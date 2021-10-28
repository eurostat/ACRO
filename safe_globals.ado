* safe_globals.ado
* Stata implementation of ACRO ('safe SDC' intercession)
* Created September 2020 by Felix Ritchie and Lizzie Green


* Copyright © European Commission. This software is released under the EUPL version 1.2.
* Acknowledgments: This code was developed as output of a project entitled "Access to European Microdata in Eurostat Safe Centre: Automatic checking of the output" (Specific Contract N° 000058 ESTAT N°2019.0337, under the Framework Contract 2018.0086) by Elizabeth Green, Felix Ritchie and Jim Smith of the University of the West of England, Bristol. 
* For queries contact estat-confidentiality@ec.europa.eu. 


* This program sets up all the global macro codes for programs, file names etc
* It also contains the SDC vaules to be set by the system manager 
* set up his or her own file location etc 


capture program drop safe_globals

program define safe_globals , rclass
		
		quietly {
		
    *********************************************************************************
		  * SYSTEM MANAGERS - EDIT THESE VALUES FOR YOUR ORGANISATIONAL SETUP             *
    *********************************************************************************
		
    *********************************************************************************
    * Template for output spreadsheet - include the full path name                  *
    *********************************************************************************
				
    global ACRO_output_template_file = "ACRO output template v01b.xlsm"
		
    *********************************************************************************
    * SDC parameters                                                                *
    *********************************************************************************
    * 1. Default values                                                                *
    *********************************************************************************

				* name used to denote that default (ie not dataset specific values) are being used
				global safe_SDC_set = "Default"

    * These are the tests to be run: include any or all of "threshold", "maxmin", "nk", or "pratio"
				global safe_tests = "threshold nk pratio maxmin"
				
    * frequency and degrees-of-freedom thresholds (latter is used for safe analytical stats)
    global safe_threshold = 10
    global safe_dof_threshold = 10

    * parameters for n, k tes: largest n values account for less than k% of the total
    global safe_nk_n = 2
    global safe_nk_k = 0.90

    * parameter for p-ration test: sum of smallest N-2 values accounts for at least p% of largest
    global safe_pratio_p = 0.10

    *********************************************************************************
    * 2. Insert here values for particular datasets                                 *
				* Note follow exactly the examples below - add dataset name to end of macro     *
				* Omit any value you don't want to change                                       *
    *********************************************************************************

 			* These are the datasets that have specific SDC rules
				global safe_SDC_variations = "CIS ESS"

    global safe_thresholdCIS = 60
    global safe_nk_nCIS = 5
    global safe_nk_kCIS = 0.50
				global safe_testsCIS = "threshold nk pratio"

    global safe_thresholdESS = 15
    global safe_dof_thresholdESS = 10
    global safe_nk_nESS = 2
    global safe_nk_kESS = 0.90
    global safe_pratio_pESS = 0.15
				global safe_testsESS = "nk pratio"
			
			
    *********************************************************************************
		  * DO NOT EDIT THESE SECTIONS                                                    * 
    *********************************************************************************

 				
    *********************************************************************************
    * defaults for parameters which are given values by 'safe setup.ado'            *
    *********************************************************************************

    * full path name of working folder - default
    global ACRO_res_folder = "C:\temp"

    * full path name of spreadsheet to be used - default
    global ACRO_out_name = "safe_results.xlsm"
    global ACRO_out_file = "$res_folder\\\$ACRO_out_name"

    * whether to automatically suppress or not if problems found - default is not
    global ACRO_suppress = 0


    * numbering for sheets not specified not recognised - reset by calling the set up program
				* the second is used when each 'by' iteraion goes on a separte sheet eg as in estimation (char(65) is "A")

    global ACRO_output_num = 1
				global Char_A = 65
				global ACRO_by_count = $Char_A
								
    *********************************************************************************
    * program parameters - should not normally be changed                           *
    *********************************************************************************

    * classes of outcome

    global ACRO_outcome_f = 0
    global ACRO_outcome_f_suppress = 1
    global ACRO_outcome_f_exception = 2
    global ACRO_outcome_f_review = 3
				global ACRO_outcome_f_dof = 4
    global ACRO_outcome_p = 10

    global ACRO_outcome_label0  = "fail"
    global ACRO_outcome_label1  = "fail; suppression applied"
    global ACRO_outcome_label2  = "fail; exception requested"
    global ACRO_outcome_label3  = "review required"
    global ACRO_outcome_label4  = "fail; insufficient degrees of freedom"
    global ACRO_outcome_label10 = "pass"
				forvalues nn = 0/10 {
				  global ACRO_outcome_labels = `" $ACRO_outcome_labels `nn' " ${ACRO_outcome_label`nn'}""'
				}

    * where temporary results are stored - necessary for communication between programs
    global ACRO_temp_results_file = "ACRO_temp_results.dta"
    global ACRO_temp_image_file = "ACRO_temp_image.png"
    global ACRO_temp_index_file = "ACRO_temp_index.dta"
    global ACRO_temp_log_file = "ACRO_temp_log.log"


				*************************************************************************************
				* Acceptable commands currently programmed                                           *
				*************************************************************************************
    * Note:                                                                             *
    *   some commands (estimates, graph) are in two parts                               *
    *   all graphs are 'for review' so subset of comands not specified                  *
    *   only 'estimates table' is relevant; "estimates stat" is generated automatically * 
    *************************************************************************************

    global ACRO_cmds_tabular = "sum summarize tab tabulate table"
    global ACRO_cmds_estimates_e = "regress xtreg test logit probit"
    global ACRO_cmds_estimates_r = "ttest"
    global ACRO_cmds_graph1 = "graph twoway matrix bar dot box pie histogram symplot quantile qnorm"
    global ACRO_cmds_graph2 = "pnorm qchi pchi qqplot gladder qladder spikeplot dotplot sunflower"
    global ACRO_cmds_twoway1 = "scatter line connected scatteri  area bar spike dropline dot  rarea rbar rspike"
    global ACRO_cmds_twoway2 = "rcap rcapsym rscatter rline rconnected  pcspike pccapsym pcarrow pcbarrow pcscatter"
    global ACRO_cmds_twoway3 = "pci pcarrowi  tsline tsrline  contour contourline mband mspline lowess lfit qfit "
    global ACRO_cmds_twoway4 = "fpfit lfitci qfitci fpfitci  function histogram kdensity lpoly lpolyci"
    global ACRO_cmds_other = "anova"
    global ACRO_cmds_double = "estimates"
				
		}
		* end quietly
		
end
* end of program 'safe'
