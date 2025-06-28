*cd "~\Documents\HHSterminations\data"
cd "~\Documents\git\HHSterminations\data"

import excel "HHS_Grants_Terminated_raw.xlsx", ///
	sheet("Table 1") firstrow clear

rename AwardingOffice awarding_office
rename FAIN fain
rename AwardNumber award_num
rename RecipientName recipient_name
rename ActionDateDateTerminated date_terminated
rename TotalAmountObligated amt_obligated
rename TotalAmountExpended amt_expended
rename TotalPaymentAmountAsofTerm total_payment_amt
rename UnliquidatedObligationsAsof amt_unliquidated
rename AwardTitle award_title
rename PresidentialAction pres_action
rename ForCausePutXifapplicable for_cause

ds, has(type string) 
local string_vars `r(varlist)'

foreach var of local string_vars {
	di "Variable = `var'"
    cap noisily replace `var' = subinstr(`var',"`=char(9)'"," ",.)	// Converts tabs to regular spaces
    cap noisily replace `var' = subinstr(`var',"`=char(10)'"," ",.)	// Converts line feeds  
    cap noisily replace `var' = subinstr(`var',"`=char(11)'"," ",.)	// Converts vertical tabs
    cap noisily replace `var' = subinstr(`var',"`=char(12)'"," ",.)	// Converts form feeds
    cap noisily replace `var' = subinstr(`var',"`=char(13)'"," ",.)	// Converts carriage returns
    cap noisily replace `var' = strtrim(`var')	// Removes leading and trailing whitespace 
    cap noisily replace `var' = stritrim(`var')	// Removes excess internal spaces
    cap noisily replace `var' = ustrtrim(`var')	// Unicode-aware version for removing leading and trailing whitespace
	cap noisily replace `var' = upper(`var')
}

foreach var of varlist amt_obligated amt_expended total_payment_amt amt_unliquidated {
	cap noisily list `var' if missing(real(`var'))
	cap noisily replace `var' = "" if missing(real(`var'))
	cap noisily destring `var', replace
	
	format `var' %16.0fc
}

tab pres_action, mi
replace pres_action = "N/A - Departmental Authority" if strpos(lower(pres_action),"departmental") != 0
replace pres_action = "N/A - Termination for Cause" if strpos(lower(pres_action),"termination for") != 0
tab pres_action, mi

gen for_cause_num = for_cause == "X"
label var for_cause_num "For Cause"

compress

merge m:1 recipient_name using "crosswalk.dta", ///
	keep(master match) gen(merge_xwalk) keepusing(recip_name_standardized org_type)
	
drop merge_xwalk

order awarding_office fain award_num org_type recip_name_standardized
compress

gsort org_type recip_name_standardized date_terminated award_num

save "HHS_Grants_Terminated.dta", replace

export delimited using "HHS_Grants_Terminated.csv", quote replace

label var recip_name_standardized "Standardized Recipient Name"

export excel using "HHS_Grants_Terminated.xlsx", firstrow(varlabels) replace