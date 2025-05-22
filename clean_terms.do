cd "~\Documents\HHSterminations\data"

import excel "HHS_Grants_Terminated.xlsx", ///
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

save "HHS_Grants_Terminated.dta"

export delimited using "HHS_Grants_Terminated.csv", quote

clear