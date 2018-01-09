* Make RCT data for testing

cap prog drop makerctdata
prog define makerctdata
args seed

clear
set seed `seed'

drawnorm p_int p_t, n(200) corr(1, .3 \ .3, 1)

gen id = _n
gen trt = (id > `=_N/2')

expand 4
bys id: gen visit = _n - 1

gen date = mdy(01, 01, 2000) if visit == 0
replace date = mdy(07, 01, 2000) if visit == 1
replace date = mdy(01, 01, 2001) if visit == 2
replace date = mdy(07, 01, 2001) if visit == 3
format date %td

bys id (visit): gen t_diff = (date - date[_n-1])/365.25

gen time = 0 if visit == 0
bys id (visit): replace time = time[_n-1] + t_diff if time == .


gen y = (-2 * time) + (1 * time * trt) + (p_int) + (p_t * time) + rnormal()

end
