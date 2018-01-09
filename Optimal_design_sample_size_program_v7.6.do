/*
Optimal design do file

Written by: Stephen Nash (based upon code by Amy Mulick & Chris Frost)
Date created: 6th February 2017
Date published: 

This creates a program which can be used to get a sample size

Requirements:
	a) A dataset of cohort data, with a case/control variable
	b) An outcome measure on a cts scale, with repeat measures, and 
		variables specified below.

Parameter:
	A single variable, which represents the outcome.

Required options:
	subject - a variable identifying each subject
	casecon - a variable identifying the two groups (must be binary)
	time - time from baseline visit
	schedule - a numlist specifying when visits in the planned trial will occur.
				It must contain only whole numbers >=1, and be in the same 
				timescale as the visit variable. A baseline visit is assumed; 
				this list should contain numbers greater than zero.
				For instance, if visits are planned at 1, 3, and 5 years, 
				you would enter schedule(1 3 5).

Optional options:
	model - 1: if the trial’s treatment is expected to reduce change to the change expected in a healthy population (i.e. if your observational data has controls)
			2: for trials where the treatment could potentially reduce change to 0 (i.e. your observational data has no controls).
			3: RCT data - requires treat/placebo option.
			The default is 1.
	iter - the number of iterations you want the model to perform. (default=10)
	alpha - the alpha for sample size calc; a number between 0-1. (default=0.05)
	power - the power for the sample size calc a number between 0-1. (default=0.8)
	contvar - if it's 
	effectiveness - the estimated percentage effectiveness of treatment.
					100% implies that the slope of the cases will be improved by 
					treatment to be the same as the slope for controls.
					A number between 0-1. (default=0.25)
Output:
	a) A sample size

Still to do:
	Dialog boxes
	Help file - Look at swpermute - Jenny's program
	In Help file - explain "mixed" will replay model
	Return r(table)
*/
cap prog drop samy76
prog define samy76 , rclass
	version 14 // Change this & check results are the same with final code.
	syntax varname(max=1) [if], SUBJect(varname) TIMe(varname) SCHEDule(numlist ascending integer >=1) ///
		[MODel(integer 1) CASEcon(varname) TReat(varname) SCAle(real 1) ITer(integer 16000) Alpha(real 0.05) ///
		 POWer(string) n(string) EFFectiveness(string) VISit(varname) DROPouts(numlist) noCONTVar USETrt]

		* Must have the outcome variable after the command
		* Required options:
			* ID for subjects
			* Case-control variable. Must be binary
			* Time variable - in the same units as the visit schedule
			* Visit schedule - a list of intergers, ascending order, of when follow-up visits are scheduled (same scale as time variable)
			* Plus optionally: number of iterations for the model, scale (how many units of time is one unit in the schedule list?), and alpha, beta, and effectiveness for the sample size calc
		preserve // We're going to change the data - drop rows and create new vars

			*************************************
			**
			** SYNTAX SECTION - CHECK THE PARAMETERS and CREATE SOME LOCALS
			**
			*************************************
			qui {
				marksample touse
				local outcome `varlist' // Just to make the code easier to understand
				if (`model' > 3.5){ // 
					display as error _n "Invalid model option"
					exit 198
				}
				*if "`dots'"=="dots" local dots emdots
				
				* If model is 1, then must have a casecontrol variable
				if (`model'==1) & ("`casecon'"=="") {
						display as error _n "You must provide a case-control variable for this model choice"
						exit 198
				}
				*
				* Must specify one of power or N: 4 possible cases...
				* 1
				if "`power'"!="" & "`n'"!="" { // 1. Both power an n specified - error
					display as error "Cannot specify both power and n"
					exit 198
					}
				* 2
				if "`power'"!="" & "`n'"=="" { // 2. Power is specified, n is missing - okay - calculate SAMPLE SIZE (N)
					local given_power=real("`power'")
					if missing(`given_power') { // ...but power isn't a number
						dis as error "Power must be a real number between 0 and 1"
						exit 198
					}
					local power_or_n power
				}
				* 3
				if "`power'"=="" & "`n'"!="" { // 3. Power is absent, n is specified - okay - calculate POWER
					local given_n=real("`n'")
					if missing(`given_n') { // ...but n isn't a number
						dis as error "N must be a numerical value"
						exit 198
					}
					local power_or_n n
				}
				* 4
				if "`power'"=="" & "`n'"=="" {
					local given_power = 0.8 // 4. Both power and n absent: okay, use default value for power - calculate SAMPLE SIZE (N)
					local power_or_n power
				}
				*
				* Check which combination of effectiveness and usetrt have been sepcified
					* Can not specify both usetrt and effectiveness 
					* If usetrt is not specified effectiveness is as the user inputs, 
					* Unless not specified, in which case default is used (25%)
						if "`usetrt'"!="" & "`effectiveness'"!="" { // Both specified
							dis as error "Cannot specify both usetrt and effectiveness"
							exit 198
						}
						if "`usetrt'"=="" & "`effectiveness'"=="" local effectiveness 0.25 // Both missing
						* Now check effectivenes is a number >0 and <= 100
							if "`effectiveness'"!="" { // Effectiveness is specified
								capture confirm number `effectiveness'
									if _rc {
										dis as error "Effectiveness must be a number between 0 and 100"
										exit 198
									}
								if `effectiveness' > 1 {
									dis as error "Effectiveness must be less than 100"
									exit 198
								}
								if `effectiveness' <=0 {
									dis as error "Effectiveness must be greater than 0"
									exit 198
								}
							}
				*
				* Check values
				if "`power_or_n'"=="power" { // Power is specified - we already know it's a number.
					if `given_power'>=1 {
						dis as error "Power must be a value strictly less than 1"
						exit 198
					}
					if `given_power'<=0 {
						dis as error "Power must be a value greater than zero"
						exit 198
					}
				}
				if "`power_or_n'" == "n" { // N is specified - we already know it's a number
					local given_n = ceil(`given_n')
					if `given_n'<=1 {
						dis as error "N must be a number greater or equal to 1"
						exit 198
					}
				}
				* Finally, rename the ???
				*
				* If model is 3 (RCT), then must have a treatment variable - do the same as above - 4 scenarios, then define default - input as string above
				if (`model'==3) {
					if "`treat'"=="" {
						display as error _n "You must provide a treatment variable for this model choice"
						exit 198
					}
					if "`usetrt'"!="" & "`effectiveness'"!="" {
						display as error "You cannot specify both usetrt and an effectiveness."
						*dis as error "Effectiveness is assumed to be equivalent to the treatment effect seen in the data."
						exit 198
						}
				} // end Model 3 checks
				* Length of schedule list:
					local sched_length = 0
					foreach i of numlist `schedule' {
						local sched_length = `sched_length ' + 1
					}
				* Decant the schedule numlist into locals
				local j = 1 // counter - position number
				foreach i of numlist `schedule' {
					local sched`j++' = `i'
				}
				* Get a nice schedule string with commas for output
					foreach i of numlist `schedule' {
						local sched_string `"`sched_string'`i', "' // Adds commas to the numlist, for use in output
					}
					* Remove the last comma from the schedule string
						local ss = strlen("`sched_string'") - 2
						local sched_string = substr("`sched_string'", 1, `ss')
				
				* Is there a dropout list specified?
					local drop_yes = 0
					if "`dropouts'"!="" local drop_yes = 1
				
				* Decant dropout numlist into locals and calculate people who attend all visits
				local dfrac_complete = 1 // The proportion attending all visits - one unless dropouts specified
				if `drop_yes'==1 {
					local j = 1 // counter - position number
					foreach fr of numlist `dropouts' {
						local dfrac`sched`j'' = `fr'
						local j = `j' + 1
						local dfrac_complete = `dfrac_complete' - `fr'
					}
					* Check the drop matrix adds up to less than 100%
						if `dfrac_complete' < 0 {
							display as error _n "Dropouts cannot exceed 100%"
							exit 198
						}
					* Drop matrix must be same length as Schedule matrix
							* Length of dropout list
							local drop_length = 0
							foreach i of numlist `dropouts' {
								local drop_length = `drop_length ' + 1
							}
						* Is this equal to schedule matrix?
						if `sched_length' != `drop_length' {
							dis as error _n "Dropout list must correspond with visit schedule"
							exit 198
						}
						* Get a nice schedule string with commas for output
							local j = 0 // counter - position in schedule list
							local sched_string ""
							foreach i of numlist `schedule' {
								local sched_string `"`sched_string'`i' (0`dfrac`i''), "' // Adds commas to the numlist, for use in output
							}
							* Remove the last comma from the schedule string
								local ss = strlen("`sched_string'") - 2
								local sched_string = substr("`sched_string'", 1, `ss')
					} // End if drop_yes
			}
			
			*************************************
			**
			** DATA SECTION
			**
			*************************************
			qui {
				tempname nmeas
				* Drop if outside the sample to use
					drop if !`touse'
				* Rescale the data
					replace `time' = `time' / `scale'
				* Check that each subject has at least two measurements - drop if not
				/*
					bysort `subject' : gen `nmeas' = _N
					drop if `nmeas'==0 // keep nmeas==1 "| `nmeas'==1 "
				*/
				* Drop if no outcome variable - the model will probably ignore but safest this way
					drop if missing(`outcome')

				* Make the time var start at 0
					sum `time'
					replace `time' = `time' - r(min)
					if r(min)!=0 dis "Warning: time variable did not start at zero. It has been adjusted to start at zero in the sample size modelling"

				* If model 1 create case/control vars
				if (`model'==1) {
					tempname case control timecase timecontrol
					gen `case' = (`casecon'!=0)
					gen `control' = (`casecon'==0)
					gen `timecase' = `time'*`case'
					gen `timecontrol' = `time'*`control'
				}

				* If model is 3 (RCT), make a placebo var from the treat var
					if (`model'==3) {
						tempname placebo
						gen `placebo'=(`treat'==0)
					}

			}

			*************************************
			**
			** MODEL SECTION
			**
			*************************************
			qui {
				tempname mbeta slope0 slope2 var_slope var_int cov_slopeint var_res var_visit
				
				* Which model are we using: 1=clinical, 2=uhdrs (need better names for these!)
				*************************
				*************************
				** 			MODEL 1
				*************************
				*************************
				if `model'==1 { // Cases and controls
					if "`contvar'"=="" { // Controls are allowed a variance parameter
						mixed `outcome' `case'##c.`time' `if' /// 
							|| `subject': `timecase' `case', cov(uns) nocons ///
							|| `subject': `timecontrol' `control', cov(uns) nocons ///
							res(ind, by(`case')) reml iter(`iter')
						matrix `mbeta'=e(b) // A 1x14 matrix
						scalar `slope0'=`mbeta'[1,3] // fixed time - ie time slope for controls
						scalar `slope2'=`mbeta'[1,3] + `mbeta'[1,5] // time + case#time interaction - ie time slope for cases
						scalar `var_slope'=(exp(`mbeta'[1,7]))^2 // Variance of time for gene-positives
						scalar `var_int'=(exp(`mbeta'[1,8]))^2 // Variance of casepos - var of intercept for CASES
						scalar `cov_slopeint'=tanh(`mbeta'[1,9])*exp(`mbeta'[1,7])*exp(`mbeta'[1,8]) // Covariance of time and casepos = b[1,10] + exp2(b8) + exp2(b9)
						scalar `var_res'=(exp(`mbeta'[1,13]+`mbeta'[1,14]))^2 // Residual variance for cases
					} // end of nested if (for control variance)
					else { // Drop the variance parameter for controls
						mixed `outcome' `case'##c.`time' `if' /// 
							|| `subject': `timecase' `case', cov(uns) nocons ///
							|| `subject': `control', cov(id) nocons ///
							res(ind, by(`case')) reml iter(`iter') coeflegend
						matrix `mbeta'=e(b) // A 1x12 matrix
						scalar `slope0'=`mbeta'[1,3] // fixed time - ie time slope for controls
						scalar `slope2'=`mbeta'[1,3] + `mbeta'[1,5] // time + case#time interaction - ie time slope for cases
						scalar `var_slope'=(exp(`mbeta'[1,7]))^2 // Variance of time for gene-positives
						scalar `var_int'=(exp(`mbeta'[1,8]))^2 // Variance of casepos - var of intercept for CASES
						scalar `cov_slopeint'=tanh(`mbeta'[1,9])*exp(`mbeta'[1,7])*exp(`mbeta'[1,8]) // Covariance of time and casepos = b[1,10] + exp2(b8) + exp2(b9)
						scalar `var_res'=(exp(`mbeta'[1,11]+`mbeta'[1,12]))^2 // Residual variance for cases
					} // end else (var param for controls)
				} // end Model 1
			
				*************************
				*************************
				** 			MODEL 2
				*************************
				*************************
				else if `model'==2 { // No controls - assume we can get slope (a fraction of the way) to zero
					noi mixed `outcome' c.`time' `if' ///
					|| `subject': `time', cov(uns) reml iter(`iter')
					matrix `mbeta'=e(b)
					scalar `slope0' = 0 // For consistency with other models
					scalar `slope2'=`mbeta'[1,1]
					scalar `var_slope'=(exp(`mbeta'[1,3]))^2 // var(time) in subject
					scalar `var_int'=(exp(`mbeta'[1,4]))^2 // var(cons) in subject
					scalar `cov_slopeint'=tanh(`mbeta'[1,5])*exp(`mbeta'[1,3])*exp(`mbeta'[1,4]) 
					scalar `var_res'=(exp(`mbeta'[1,6]))^2
					} // end Model 2

				*************************
				*************************
				** 			MODEL 3
				*************************
				*************************
				else if `model'==3 { // RCT data
					mixed `outcome' `time' `placebo'#c.`time' `if' /// 
						|| `subject': `time', cov(uns) reml iter(`iter')
					matrix `mbeta'=e(b) // A 1x8 matrix
					scalar `slope0' = 0 // Default option is to ignore the slope for treated
					if "`usetrt'"!="" { // Use the treatment effect from the RCT
						scalar `slope0'=`mbeta'[1,1] // time + trt#time interaction - ie time slope for treated group
						local effectiveness = 1
					 }
					scalar `slope2'=`mbeta'[1,1] + `mbeta'[1,3] // slope over time - ie time slope for placebo group
					scalar `var_slope'=(exp(`mbeta'[1,5]))^2 // Variance of time 
					scalar `var_int'=(exp(`mbeta'[1,6]))^2 // Variance of intercept 
					scalar `cov_slopeint'=tanh(`mbeta'[1,7])*exp(`mbeta'[1,5])*exp(`mbeta'[1,6]) // Covariance of slopes and intercepts
					scalar `var_res'=(exp(`mbeta'[1,8]))^2 // Residual variance
				} // end Model 3
			} // end of quitely

			*************************************
			**
			** MATRIX SECTION
			**
			*************************************
			* if flag=no_error...
			qui {
				tempname V VSTAR X DSTAR XSTAR F1STAR FSTAR visit_matrix COV
				foreach i of numlist `schedule' {
					tempname DROP`i' DROP`i'STAR DROP
				}
				* First I need to make a visit schedule matrix (what Amy called D1, D2 etc) and I call visit_matrix
				* from the user inputted visit schedule, which is just a numlist...
	
				* What's the biggest number (=number of timepoints), and how many are in the list? (vvv)
					local vvv = 0 // This will count the elements of the numlist
					foreach i of numlist `schedule' { // We want: (i) timepoint of last visit (ii) number of visits and (iii) a nice string of visit times
						local tpoints = `i' + 1
						local vvv = `vvv' + 1
					}
				* Add one to the number in the list to get the number of rows we need visit_matrix to have
					local vplus1 = `vvv' + 1
				* Make a `vplus1' x `tpoints' matrix, all zeros
					mat `visit_matrix' = J(`vplus1', `tpoints', 0)
				* Make the first row 1, 0, 0... 
					mat `visit_matrix'[1,1] = 1
				* Fill in the (i+1,j+1) element (=1) where j is the value of the ith number
					local i = 2 // We need the +1's because our matric starts with timepoint 0
					foreach j of numlist `schedule' {
						local jjj = `j' + 1
						mat `visit_matrix'[`i', `jjj'] = 1
						local i = `i' + 1
					}

				* These scalars make a matrix
					local tpminus1 = `tpoints' - 1
				* Do diagonal first
					forvalues i=1/`tpoints' {
						local v_`i'_`i' = (`var_int')+(`var_res')+(((`i'-1)^2)*(`var_slope'))+ (2*(`i'-1)*`cov_slopeint')
					}
				* Then the bottom left corner
					forvalues j=1/`tpminus1' {
						local jplus1 = `j' + 1
						forvalues i=`jplus1' / `tpoints' {
							local v_`i'_`j' = (`var_int') + ( (`j'-1)*(`i'-1)*`var_slope') + ( (`j'-1+`i'-1)*`cov_slopeint' )
						} // i
					} // j
				* Now fill in the top right corner by symmetry
					forvalues i=1 / `tpoints' {
						local iplus1 = `i' + 1
						forvalues j=`iplus1' / `tpoints' {
							local v_`i'_`j' = `v_`j'_`i''
						}
					}
				* This matrix V is constructed in a loop using the above values
					matrix `V' = J(`tpoints', `tpoints', 0) // create a blank matrix of the right size
					forvalues i=1/`tpoints' {
						forvalues j=1 / `tpoints' {
							mat `V'[`i', `j'] = `v_`i'_`j''	
						} // i
					} // j

				* Matrix VSTAR
					* Define bottom-left and top-right matrices (COV)
						matrix `COV' = 0*I(`tpoints') // Zeroes everywhere in a square matrix
					* Vstar
					matrix `VSTAR'=(`V',`COV' \ `COV',`V')

				* Matrix X
					matrix `X' = J(`tpoints', 2, 1)
					forvalues i=1/`tpoints' {
						matrix `X'[`i', 2] = `i' - 1
					}
					
				* Make dropout matrices: one for each visit (dropping out BEFORE that visit)
				if `drop_yes'==1 {
					* First, make an indicator matrix
					* Start making it the right size, all zeros, then add 1's...
					local j = 1 // row counter = position in schedule numlist
					matrix `DROP`sched1'' = J(1,`tpoints', 0)
					matrix `DROP`sched1''[1,1] = 1
					forvalues i=2/`vvv' {
						local lag = `i' - 1
						matrix `DROP`sched`i''' = `DROP`sched`lag''' \ J(1, `tpoints', 0) // Add one row at a time
						* Get correct column pos'n for the 1
							local ccc = `sched`lag'' + 1
						matrix `DROP`sched`i'''[`i',`ccc'] = 1
					}
					* Matrix DROPSTAR
					foreach nnn of numlist `schedule' {
						matrix `DROP`nnn'STAR'=(`DROP`nnn'', 0*`DROP`nnn'' \ 0*`DROP`nnn'',`DROP`nnn'')
					}
				} // End if drop_yes

				* Make matrix DSTAR
					matrix `DSTAR'=(`visit_matrix',0*`visit_matrix' \ 0*`visit_matrix',`visit_matrix')

				* Make matrix XSTAR
					matrix `XSTAR' = J(2*`tpoints', 3, 1) // So the first colum is done - all 1s
					forvalues j=1/`tpoints' { // Top of the second column
						matrix `XSTAR'[`j', 2] = `j' - 1
					}
					local aa = `tpoints' + 1
					local bb = `tpoints' * 2
					forvalues j=`aa'/`bb' { // Bottom half of second column
						matrix `XSTAR'[`j', 2] = `j' - 1 - `tpoints'
					}
					forvalues j=1/`tpoints' { // Top of the third column
						matrix `XSTAR'[`j', 3] = 0
					}
					forvalues j=`aa'/`bb' { // Bottom half of third column
						matrix `XSTAR'[`j', 3] = `j' - `tpoints' - 1
					}

					* Matrices FDROPiSTAR
					if `drop_yes'==1 {
						foreach nnn of numlist `schedule' {
							if `nnn'==`sched1' continue
							tempname FDROP`nnn'STAR
							matrix `FDROP`nnn'STAR' = inv((`DROP`nnn'STAR'*`XSTAR')' * ///
											  inv(`DROP`nnn'STAR'*`VSTAR'*`DROP`nnn'STAR'') * ///
											  `DROP`nnn'STAR'*`XSTAR')
						}
					} //end if drop_yes

				* Matrix FSTAR
				  matrix `FSTAR' = inv((`DSTAR'*`XSTAR')'* /// That last ' is for "matrix transpose"
									  inv(`DSTAR'*`VSTAR'*`DSTAR'')* ///
									  `DSTAR'*`XSTAR')
			} // End of qui

			*************************************
			**
			** CALCULATE THE RETURN VALUES
			**
			*************************************
			qui {
				tempname es_slope var1 sampfactor alpha_tail sampsize power z_power
				if e(converged) {
					* Slope
						scalar `es_slope'=`slope2'-`slope0'
					* Main variance and effect size component
						scalar `var1' = `FSTAR'[3,3]
						local part_effsize =  `es_slope' / sqrt(`var1') // use this to get an N (below)

					* Dropout variances and effect size components
					if `drop_yes'==1 {
						foreach nnn of numlist `schedule' {
							if `nnn' == `sched1' continue
							tempname var_drop_`nnn'
							scalar `var_drop_`nnn'' = `FDROP`nnn'STAR'[3,3]
							local effsize_drop`nnn' = `es_slope' / sqrt(`var_drop_`nnn'')
						} // End for
					} // end if drop_yes

					* Combine all effect size components into one overall effect size
						local eff_bit = `dfrac_complete' * (`part_effsize')^2
						if `drop_yes'==1 {
							foreach nnn of numlist `schedule' {
								if `nnn' == `sched1' continue
								local eff_bit = `eff_bit' + (`dfrac`nnn'' * (`effsize_drop`nnn'')^2)
								}
							} // end if drop_yes

					* Calculate the EFFECT SIZE
						local effsize=sign(`es_slope') * sqrt(`eff_bit')
					
					* CALCULATE THE MAIN RESULT: Either sample size or power
						if "`power_or_n'"=="power" { // Calc SAMPLE SIZE
							scalar `alpha_tail' = 1 - (0.5 * `alpha')
							scalar `sampfactor' = ( invnormal(`alpha_tail') + invnormal(`given_power'))^2
							scalar `sampsize' = ceil( ( `sampfactor' / (`effsize')^2) / `effectiveness'^2)
							scalar `power' = `given_power' // Transferring the local into the scalar...
						}
						else { // Calc POWER
							// Calc the power here
							scalar `sampsize' = `given_n' // As specified by the user, just transferring to output scalar
							scalar `z_power' = ( abs(`effsize')*`effectiveness'/sqrt(2*`given_n') ) - invnormal(1-`alpha'/2)
							scalar `power' = normal(`z_power')
							
						}
				} // end converged bit
				else { // Model didn't converge...
					noi display as error "Model did not converge"
						scalar `es_slope' = . // Return null values
						scalar `var1' = .
						local effsize = .
						local sampsize = .
				} // end else
					
				return scalar slope = `es_slope'
				return scalar var = `var1'
				return scalar effsize = `effsize'
				return scalar sampsize = `sampsize'
				return scalar fupvisits = `vvv'
				return scalar power = `power'
				return scalar alpha = `alpha'
			} // End qui

			*************************************
			**
			** MAKE A MATRIX OF RETURN VALUES
			**
			*************************************
			qui {
				tempname RESULTS
				mat `RESULTS' = J(1, 9 ,.)
				mat colnames `RESULTS' = alpha power N N1 N2 slope trt effectiveness var
				mat `RESULTS'[1,1] = `alpha'
				mat `RESULTS'[1,2] = `power'
				mat `RESULTS'[1,3] = 2 * `sampsize'
				mat `RESULTS'[1,4] = `sampsize'
				mat `RESULTS'[1,5] = `sampsize'
				mat `RESULTS'[1,6] = `es_slope'
				mat `RESULTS'[1,7] = `effsize'
				mat `RESULTS'[1,8] = `effectiveness'
				mat `RESULTS'[1,9] = `var1'
				return matrix rtable = `RESULTS'
			}

			*************************************
			**
			** DISPLAY THE RESULTS
			**
			*************************************
				* The display format depends on whether we are calculating POWER or
				* a SAMPLE SIZE (N)
					if "`power_or_n'"=="power" { // Power is given, so we're calculating SAMPLE SIZE
						display as text _n "Study parameters:" _n
						display as text "                     alpha =  " as result %6.4f round(`alpha', 0.0001)
						display as text "                     power =  " as result %6.4f round(`power', 0.0001)
						display as text "             effectiveness = " as result %4.2f round(`effectiveness')
						display as text "number of follow-up visits = " as result `vvv'
						display as text "   schedule (and dropouts) : " as result "`sched_string'"
						display as text "                     scale = " as result `scale'
						display _n
						display as text "Estimated sample size:" _n
						display as text "                         N = " as result 2 * `sampsize'
						display as text "                 N per arm = " as result `sampsize'
					}
				
					if "`power_or_n'"=="n" { // N is given, so we're calculating POWER
						display as text _n "Study parameters:" _n
						display as text "                     alpha = " as result %6.4f round(`alpha', 0.0001)
						display as text "                         N =   " as result " `n'
						display as text "             effectiveness =  " as result %4.2f round(`effectiveness')
						display as text "number of follow-up visits = " as result `vvv'
						display as text "   schedule (and dropouts) : " as result "`sched_string'"
						display as text "                     scale = " as result `scale'
						display _n
						display as text "Estimated power:" _n
						display as text "                    power = " as result %6.4f round(`power', 0.0001)
					}
	

				/*
				Rate of change in control arm: es_slope
				Treatment effectiveness: % or from previous study
				Treatment effect: es_slope * effectiveness
				Variance of treatment effect: (es_slope / effsize)^2				
				*/
				
		restore

end // of program!
