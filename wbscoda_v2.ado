*============================================================================
* wbscoda_v2: read MCMC results written in CODA format modified for JAGS
* Author: John Thompson
* Date: Nov 2014
*============================================================================
version 12.1
program wbscoda_v2
syntax using/ , ///
CLEAR ///
[ Chains(numlist) ///
Keep(string) ///
Jags ///
Openbugs ]
drop _all
local root "`using'"
* ---------------------------------
* read the index file
* ---------------------------------
if "`openbugs'" == "" & "`jags'" == "" local filename = `"`root'Index.txt"'
else if "`jags'" == "" local filename = `"`root'CODAindex.txt"'
else local filename = `"`root'index.txt"'
confirm file `"`filename'"'
tempname WB
cap file open `WB' using `"`filename'"' , read
if _rc ! = 0 {
di as err `"Error reading the index file `filename'"'
exit
}
file read `WB' inLine
local tab = char(9)
local p = 0
local maxsize = 0
local lastread = 0
while r(eof) == 0 {
local ++p
tokenize "`inLine'" , parse(" `tab'")
local var`p' "`1'"
local use`p' = "n"
if "`keep'" == "" local use`p' "y"
else {
tokenize "`keep'"
local i = 1
while "``i''" != "" {
if strmatch("`var`p''","``i''") == 1 local use`p' "y"
local ++i
}
}
if "`use`p''" == "y" local lastread = `p'
tokenize "`inLine'" , parse(" `tab'")
local i = 2
if "``i''" == "`tab'" local ++i
local start`p' = ``i''
local ++i
if "``i''" == "`tab'" local ++i
local end`p' = ``i''
local size`p' = `end`p'' - `start`p'' + 1
local var`p' = subinstr("`var`p''" , "[" , "_" , .)
local var`p' = subinstr("`var`p''" , "." , "_" , .)
local var`p' = subinstr("`var`p''" , "]" , "" , .)
local var`p' = subinstr("`var`p''" , "," , "_" , .)
if `size`p'' > `maxsize' local maxsize = `size`p''
file read `WB' inLine
}
file close `WB'
local npar = `lastread'
if `npar' == 0 exit(0)
* ---------------------------------
* How many chains
* ---------------------------------
if "`chains'" == "" local chains "1"
local nchains = 0
foreach c of numlist `chains' {
local ++nchains
}
* ---------------------------------
* Set Number Obs & blank variables
* ---------------------------------
local nobs = `nchains'*`maxsize'
qui set obs `nobs'
if `nchains' > 1 qui gen chain = 0
local i = 0
foreach c of numlist `chains' {
local lb = `i'*`maxsize' + 1
local ub = `lb' + `maxsize' - 1
if `nchains' > 1 qui replace chain = `c' in `lb'/`ub'
local ++i
}
forvalues p = 1/`npar' {
if "`use`p''" == "y" qui gen `var`p'' = .
}
* ---------------------------------
* Read each data file
* ---------------------------------
local nc = 0
foreach c of numlist `chains' {
local ++nc
if "`openbugs'" == "" & "`jags'" == "" local filename = `"`root'`c'.txt"'
else if "`jags'" == "" local filename = `"`root'CODAchain`c'.txt"'
else local filename = `"`root'chain`c'.txt"'
confirm file `"`filename'"'
cap file open `WB' using `"`filename'"' , read
forvalues p = 1/`npar' {
local k = (`nc'-1)*`maxsize' + `maxsize' - `size`p''
if "`use`p''" == "y" {
forvalues j = 1/`size`p'' {
file read `WB' inLine
local inLine = subinstr("`inLine'","`tab'"," ",.)
local value : word 2 of `inLine'
local ++k
qui replace `var`p'' = `value' in `k'
}
}
else {
forvalues j = 1/`size`p'' {
file read `WB' inLine
}
}
}
file close `WB'
}
end
