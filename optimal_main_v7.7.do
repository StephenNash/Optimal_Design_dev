/*

Do file to run the OPTIMAL DESIGN code and get results.
Contains file paths, variable lists etc used by all other Optimal Design Do files

Written by: Stephen Nash
Date created: 17 November 2016

YOU MUST RUN THE PROGRAM DO FILE BEFORE THIS ONE

*/
version 14
cap log close

* Set main directory
	global root "C:\Users\EIDESNAS\Filr\My Files\Offline\Methods\Projects\Optimal Design\Stata" // Desktop
	*global root "C:\Users\eidesnas\Filr\My Files\Offline\Methods\Projects\Optimal Design\Stata" // Laptop
				
* File paths
	global logpath "$root\Log"
	global datapath "$root\Data"

* load the data
	use "$datapath\sdmt_data.dta", clear
		*keep if centre=="leiden"
		*replace time = time-1
		*replace sdmt = . if visit==1 in 1/100
	
	* or use random RCT data
	makerctdata 31


samy76 sdmt, subject(subject) model(1) time(time) visit(visit) casecon(case) schedule(1 2) alpha(0.05) n(1000) /*power(`power')*/ dropout(0 0.1) effectiveness(`eff1') 
*local power=r(power)
*samy76 sdmt, subject(subject) model(1) time(time) visit(visit) casecon(case) schedule(1 2) alpha(0.05) /*n(50)*/ power(`power') dropout(0.1 0.1) effectiveness(`eff1')
 

*samy76 sdmt, subject(subject) model(1) /*nocontvar*/  time(time) visit(visit) casecon(case) schedule(1 2) iter(`iter') alpha(0.05) n(50) /*power(`power')*/ dropout(0.1 0.1) effectiveness(`eff1')
*samy76 sdmt, subject(subject) model(1) time(time) visit(visit) casecon(case) schedule(1 5) iter(`iter') alpha(`alpha') power(`power') dropout(0.1 0.1) effectiveness(`eff2')
*samy76 y, subject(id) model(1) time(time) usetrt visit(visit) treat(trt) schedule(1 5) iter(`iter') alpha(`alpha') power(`power')  dropout(0.1 0.1) effectiveness(`eff2') // scale(365.25)
*samy76 y, subject(id) model(3) time(time) /*usetrt*/ visit(visit) treat(trt) schedule(1 5) iter(`iter') alpha(`alpha') power(`power')  dropout(0.1 0.1) effectiveness(`eff1') // scale(365.25)
samy76 y, subject(id) model(3) time(time) /*usetrt*/ visit(visit) treat(trt) schedule(1 5) iter(16) alpha(0.05) n(200)  dropout(0.1 0.1) effectiveness(0.3) // scale(365.25)

samy76 y, subject(id) model(2) time(time) schedule(1 3) dropout(0.1 0.2) ///
	casecon(trt) alpha(0.05) n(562) effectiveness(0.25) 

/*
* DROPOUTS TEST
use "$datapath\stap_example.dta", clear
* Set parameters
	local alpha 0.05
	local power 0.9
	local effectiveness 20
	local iter 16

* SCENARIO 1
	log using "$logpath\dropout_1.txt", text replace nomsg
		samy74 log_stap, subject(subject) model(1) casecon(group2) time(time) visit(visit) centre(centre2) schedule(1) dropout(0.1) iter(`iter') alpha(`alpha') power(`power') effectiveness(`effectiveness') // scale(365.25)
		return list
	log close

* SCENARIO 2
	log using "$logpath\dropout_2.txt", text replace nomsg
		samy74 log_stap, subject(subject) model(1) casecon(group2) time(time) visit(visit) centre(centre2) schedule(1 2) dropout(0.1 0.1) iter(`iter') alpha(`alpha') power(`power') effectiveness(`effectiveness') // scale(365.25)
		return list
	log close

* SCENARIO 3
	log using "$logpath\dropout_3.txt", text replace nomsg
		samy74 log_stap, subject(subject) model(1) casecon(group2) time(time) visit(visit) centre(centre2) schedule(1 2 3) dropout(0.1 0.1 0.15) iter(`iter') alpha(`alpha') power(`power') effectiveness(`effectiveness') // scale(365.25)
		return list
	log close
*/
 
 
 
* Run the program
	*log using "$logpath\samy71_model2_centre.txt", text replace
		samy74 sdmt, subject(subject) model(2) time(time) visit(visit) schedule(1 5) iter(`iter') alpha(`alpha') power(`power') dropout(0.1 0.1) effectiveness(`effectiveness') // scale(365.25)
		return list
	*log close
 







