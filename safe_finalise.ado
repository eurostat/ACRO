* safe_finalise.ado
* Stata program to replace the index in the Excel file with the correct one

* Copyright © European Commission. This software is released under the EUPL version 1.2.
* Acknowledgments: This code was developed as output of a project entitled "Access to European Microdata in Eurostat Safe Centre: Automatic checking of the output" (Specific Contract N° 000058 ESTAT N°2019.0337, under the Framework Contract 2018.0086) by Elizabeth Green, Felix Ritchie and Jim Smith of the University of the West of England, Bristol. 
* For queries contact estat-confidentiality@ec.europa.eu. 

* V01 created September 2020 by Felix Ritchie
* Last modified:
*  dd.mm.yy vxx who what

* the code uses index file specified in 'safe_setup' to update the spreadsheet

capture program drop safe_finalise

program define safe_finalise, rclass

		quietly {
*		noisily {
		
    if "$ACRO_setup_run"=="ok" {

				  preserve

  				use "$ACRO_temp_index" , clear
		  		sort sheet
      export excel using "$ACRO_out_file", sheet("description") sheetmodify cell(a2) 
  				* need to do links using put excel as forumal otherwise don't get understodd as such
    		putexcel set "$ACRO_out_file" , sheet("description") modify 
				  local nobs = _N
      forvalues nn = 1/`nobs' {
		  		  local line_no = `nn'+1
				  		local sheetname = sheet[`nn']
        putexcel A`line_no' = formula(`"=+HYPERLINK("[$ACRO_out_name]`sheetname'!A1","`sheetname'")"')
        putexcel A`line_no', font(calibri, 11, red) bold underline
      }
				
				  foreach nn in temp_results temp_image temp_index temp_log {
  				  capture erase "${ACRO_`nn'}"
		  		}
  		  restore
		
		  }
				* end check to see if tings run
				
				global ACRO_setup_run = ""
		}
		* end quietly
		
end

		  
