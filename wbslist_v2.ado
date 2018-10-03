*============================================================================
* wbslist_v2: write data in WinBUGS list format modified for JAGS
* Author: John Thompson
* Date: Nov 2014
*============================================================================
version 12.1
program wbslist_v2
syntax anything [using/] , [ REPLACE Jags ]
* ---------------------------
* Decompose
* ---------------------------
tokenize `"`anything'"' , parse("()")
local k = 1
local i = 1
local count = 0
while "``i''" != "" {
if "``i''" == "(" local ++count
else if "``i''" == ")" local --count
if `count' == 0 local ++k
else if `count' ! = 1 | "``i''" != "(" local entry`k' `"`entry`k''``i''"'
local ++i
}
local nterm = `k' - 1
tempfile TF
* ---------------------------
* Output
* ---------------------------
if `"`using'"' == "" local using "`TF'"
tempname WB
file open `WB' using `"`using'"' , write `replace'
* For JAGS do not create a list
if "`jags'" == "" {
file write `WB' "list( "
di as res "list( " _continue
}
file close `WB'
forvalues k = 1/`nterm' {
tokenize `"`entry`k''"' , parse(" ")
local command "`1'"
local copy "`1'"
local len = strlen("`command'")
if "`command'" == substr("vectors",1,`len') local command "vector_v2"
if "`command'" == substr("variables",1,`len') local command "vector_v2"
if "`command'" == substr("scalars",1,`len') local command "scalar_v2"
if "`command'" == substr("matrix",1,`len') local command "matrix_v2"
if "`command'" == substr("matrices",1,`len') local command "matrix_v2"
if "`command'" == substr("structures",1,`len') local command "structure_v2"
if "`command'" == substr("tables",1,`len') local command "table_v2"
if inlist(`"`command'"',"vector_v2","scalar_v2","matrix_v2","structure_v2","table_v2") {
local entry`k' = subinstr(`"`entry`k''"',"`copy'","`command'",1)
if strpos(`"`entry`k''"',",") == 0 wb_`entry`k'' using `using', append nolist `jags'
else {
tokenize `"`entry`k''"' , parse(",")
wb_`1' using `using' , `3' append nolist `jags'
}
}
else wb_nokeyword_v2 `"`entry`k''"' using `using', append nolist `jags'
if `k' != `nterm' {
file open `WB' using `"`using'"' , write append
if "`jags'" == "" {
file write `WB' " ," _n
di as res " ,"
}
* else {
* file write `WB' _n
* di as res " "
* }
file close `WB'
}
}
* For JAGS there is no closing bracket
if "`jags'" == "" {
di as res ")"
file open `WB' using `"`using'"' , write append
file write `WB' " )" _n
file close `WB'
}
end



program wb_nokeyword_v2
syntax anything(equalok) [using/] , [REPLACE APPEND NOLIST JAGS]
version 8.2
tokenize `"`anything'"'
local entry ""
local i = 1
while "``i''" != "" {
local entry "`entry'``i''"
local ++i
}
tokenize "`entry'" , parse("{}()[] = , ")
local i = 1
while "``i''" != "" {
if "``i''" == "{" {
local j = `i' - 1
if "``j''" == "=" | "``j''" == "," | "``j''" == "(" local rep = 1
else {
local rep = ``j''
local `j' " "
}
local j = `i' + 1
local j1 = `j' + 1
local j2 = `j' + 2
local j3 = `j' + 3
local j4 = `j' + 4
if "``j1''" == "[" & "``j3''" == "]" & "``j4''" == "}" {
local value "``j''"
local index = ``j2''
while "``j''" != "}" {
local `j' " "
local ++j
}
local `j' " "
local `i' = `value'[`index']
forvalues k = 2/`rep' {
local ++index
local a = `value'[`index']
local `i' "``i'',`a'"
}
}
else {
local value ""
while "``j''" != "}" {
local value `"`value'``j''"'
local `j' " "
local ++j
}
local `j' " "
local `i' = `value'
forvalues k = 2/`rep' {
local a = `value'
local `i' "``i'',`a'"
}
}
local i = `j'
}
local ++i
}
local terms = `i'
forvalues i = 1/`terms' {
if "``i''" == " " local t`i' ""
else local t`i' "``i''"
}
tempname WB
file open `WB' using `using' , write `replace' `append'
local start = 1
if "`t`start''" == "list" local start = `start'+1
if "`t`start''" == "(" local start = `start'+1
else local endbracket = "y"
if "`nolist'" == "" file write `WB' "list( "
if "`nolist'" == "" di as res "list( " _continue
local len = 6
forvalues i = `start'/`terms' {
local size = strlen(`"`t`i''"')
if `len' + `size' < 80 | strpos(`"`t`i''"',",") == 0 {
file write `WB' `"`t`i''"'
di as res `"`t`i''"' _continue
local len = `len' + `size'
}
else {
tokenize `"`t`i''"' , parse(", ")
local j = 1
while "``j''" != "" {
local s = strlen("``j''")
if `len' + `s' > 80 & "``j''" == "," {
file write `WB' "," _n
di as res ","
local len = 0
}
else {
file write `WB' `"``j''"'
di as res "``j''" _continue
}
local len = `len' + `s'
local ++j
}
}
}
if "`endbracket'" == "y" & "`nolist'" == "" {
file write `WB' " )"
di as res " )" _continue
}
di as txt ""
file close `WB'
end


program wb_matrix_v2
syntax namelist [using/] , ///
[ Linesize(integer 10) ///
Formats(string) ///
REPLACE ///
APPEND ///
NOLIST ///
FORCE ///
JAGS ///
Names(string) ]
version 8.2
if "`jags'" == "" {
local assign "="
local qname ""
local endwith ","
}
else {
local assign "<-"
local qname `"""'
local endwith ""
}
* --------------------------------
* organise the formatting
* --------------------------------
if "`formats'" == "" {
local f1 = "%8.3f"
local sf1 = "%8s"
local nf = 1
}
else {
tokenize "`formats'"
local nf = 1
while "``nf''" != "" {
local f`nf' = "``nf''"
local np = index("``nf''" , ".")
local sp = substr("``nf''" , 2 , `np'-2)
local sf`nf' = "%`sp's"
local nf = `nf' + 1
}
local nf = `nf' - 1
}
local nM = 0
foreach M of local namelist {
confirm matrix `M'
local nM = `nM'+1
}
if "`names'" != "" {
tokenize "`names'"
local i = 1
while "``i''" != "" {
local name`i' = "``i''"
local i = `i' + 1
}
}
else {
tokenize "`namelist'"
local i = 1
while "``i''" != "" {
local name`i' = "``i''"
local i = `i' + 1
}
local --i
if `i' ! = `nM' {
di as err "wrong number of matrix names"
exit
}
}
* --------------------------------
* write to file if required
* --------------------------------
tempfile TF
if `"`using'"' == "" local using "`TF'"
tempname WB
file open `WB' using `using' , write `replace' `append'
if "`nolist'" == "" {
file write `WB' "list( "
di as res "list( " _continue
}
* --------------------------------
* for each matrix
* --------------------------------
local k = 0
foreach M of local namelist {
local kf = 1+mod(`k',`nf')
local k = `k'+1
local r = rowsof(`M')
local c = colsof(`M')
if `r' == 1 & `c' == 1 & "`force'" == "" {
file write `WB' `"`qname'`name`k''`qname' `assign' c("'
di as res `"`qname'`name`k''`qname' `assign' c("' _continue
local y = `M'[1,1]
if "`y'" == "." {
file write `WB' `sf`k'' ("NA") "`endwith'" _n
di as res `sf`k'' ("NA") "`endwith'"
}
else {
file write `WB' `f`k'' (`y') "`endwith'" _n
di as res `f`k'' (`y') "`endwith'"
}
}
else if `r' == 1 & "`force'" == "" {
file write `WB' `"`qname'`name`k''`qname' `assign' c("'
di as res `"`qname'`name`k''`qname' `assign' c("' _continue
forvalues j = 1/`c' {
local y = `M'[1,`j']
if "`y'" == "." {
file write `WB' `sf`k'' ("NA")
di as res `sf`k'' ("NA") _continue
}
else {
file write `WB' `f`k'' (`y')
di as res `f`k'' (`y') _continue
}
if `j' == `c' {
file write `WB' ") `endwith'" _n
di as res ")" `endwith'
}
else {
file write `WB' ","
di as res "," _continue
if mod(`j',`linesize') == 0 ) {
file write `WB' _n
di as res " "
}
}
}
}
else if `c' == 1 & "`force'" == "" {
file write `WB' `"`qname'`name`k''`qname' `assign' c("'
di as res `"`qname'`name`k''`qname' `assign' c("' _continue
forvalues i = 1/`r' {
local y = `M'[`i',1]
if "`y'" == "." {
file write `WB' `sf`k'' ("NA")
di as res `sf`k'' ("NA") _continue
}
else {
file write `WB' `f`k'' (`y')
di as res `f`k'' (`y') _continue
}
if `i' == `r' {
file write `WB' ") `endwith'" _n
di as res ")" `endwith'
}
else {
file write `WB' ","
di as res "," _continue
if mod(`i',`linesize') == 0 ) {
file write `WB' _n
di as res " "
}
}
}
}
else {
if "`jags'" == "" {
file write `WB' `"`qname'`name`k''`qname' `assign' structure(.Data = c("'
di as res `"`qname'`name`k''`qname' `assign' structure(.Data = c("' _continue
* rows and columns
forvalues i = 1/`r' {
forvalues j = 1/`c' {
local y = `M'[`i',`j']
if "`y'" == "." {
file write `WB' `sf`k'' ("NA")
di as res `sf`k'' ("NA") _continue
}
else {
file write `WB' `f`k'' (`y')
di as res `f`k'' (`y') _continue
}
if `i' == `r' & `j' == `c' {
file write `WB' "),.Dim = c(`r',`c')) `endwith'" _n
di as res "),.Dim = c(`r',`c')) `endwith'"
}
else {
file write `WB' ","
di as res "," _continue
if mod(`j',`linesize') == 0 | `j' == `c' {
file write `WB' _n
di as res " "
}
}
}
}
}
else {
file write `WB' `"`qname'`name`k''`qname' `assign' structure(c("'
di as res `"`qname'`name`k''`qname' `assign' structure(c("' _continue
* columns and rows
forvalues j = 1/`c' {
forvalues i = 1/`r' {
local y = `M'[`i',`j']
if "`y'" == "." {
file write `WB' `sf`k'' ("NA")
di as res `sf`k'' ("NA") _continue
}
else {
file write `WB' `f`k'' (`y')
di as res `f`k'' (`y') _continue
}
if `i' == `r' & `j' == `c' {
file write `WB' "),.Dim = c(`r',`c')) `endwith'" _n
di as res "),.Dim = c(`r',`c')) `endwith'"
}
else {
file write `WB' ","
di as res "," _continue
if mod(`i',`linesize') == 0 | `i' == `r' {
file write `WB' _n
di as res " "
}
}
}
}
}
}
}
if "`nolist'" == "" {
file write `WB' " )" _n
di as res " )"
}
file close `WB'
end


program wb_scalar_v2
syntax namelist [using/] , ///
[ Linesize(integer 10) ///
Formats(string) ///
REPLACE ///
APPEND ///
JAGS ///
Names(string) ///
NOLIST ]
version 8.2
if "`jags'" == "" {
local assign "="
local qname ""
local endwith ","
}
else {
local assign "<-"
local qname `"""'
local endwith ""
}
* --------------------------------
* organise the formatting
* --------------------------------
if "`formats'" == "" {
local f1 = "%8.3f"
local sf1 = "%8s"
local nf = 1
}
else {
tokenize "`formats'"
local nf = 1
while "``nf''" != "" {
local f`nf' = "``nf''"
local np = index("``nf''" , ".")
local sp = substr("``nf''" , 2 , `np'-2)
local sf`nf' = "%`sp's"
local nf = `nf' + 1
}
local nf = `nf' - 1
}
* --------------------------------
* count number of namelist
* --------------------------------
tokenize "`namelist'"
local nv = 0
foreach S of local namelist {
confirm scalar `S'
local nv = `nv' + 1
local s`nv' "`S'"
}
* -------------------------------
* variable names
* -------------------------------
if "`names'" == "" {
forvalues k = 1/`nv' {
local name`k' "`s`k''"
}
}
else {
tokenize "`names'"
local k = 1
while "``k''" != "" {
local name`k' "``k''"
local k = `k' + 1
}
local --k
if `k' ! = `nv' {
di as err "Wrong number of names"
exit
}
}
* --------------------------------
* list to file if required
* --------------------------------
tempfile TF
if `"`using'"' == "" local using "`TF'"
tempname WB
file open `WB' using `using' , write `replace' `append'
if "`nolist'" == "" {
file write `WB' "list( "
di as res "list( " _continue
}
local k = 1
forvalues c = 1 / `nv' {
file write `WB' `"`qname'`name`c''`qname' `assign' "' `f`k'' (`s`c'') "`endwith'" _n
di as res `"`qname'`name`c''`qname' `assign' "' `f`k'' (`s`c'') "`endwith'"
local ++k
if `k' > `nf' {
local k = 1
}
}
if "`nolist'" == "" {
file write `WB' ")" _n
di as res ")"
}
file close `WB'
end


program wb_structure_v2
syntax varlist(min = 2 numeric) [using/] [if] [in] , ///
[ Name(string) ///
Linesize(integer 10) ///
Formats(string) ///
NOLIST ///
REPLACE ///
JAGS ///
APPEND ]
version 8.2
marksample touse , novarlist
if "`jags'" == "" {
local assign "="
local qname ""
local endwith ","
}
else {
local assign "<-"
local qname `"""'
local endwith ""
}
tempvar ntouse
qui gen `ntouse' = _n * `touse'
qui summ `ntouse'
local last = r(max)
qui summ `touse'
local count = r(sum)
local n = _N
* --------------------------------
* organise the formatting
* --------------------------------
if "`formats'" == "" {
local f1 = "%8.3f"
local sf1 = "%8s"
local nf = 1
}
else {
tokenize "`formats'"
local nf = 1
while "``nf''" != "" {
local f`nf' = "``nf''"
local np = index("``nf''" , ".")
local sp = substr("``nf''" , 2 , `np'-2)
local sf`nf' = "%`sp's"
local nf = `nf' + 1
}
local nf = `nf' - 1
}
* --------------------------------
* count variables
* --------------------------------
tokenize "`varlist'"
if "`name'" == "" local name "`1'"
local nv = 1
while "``nv''" != "" {
local nv = `nv' + 1
}
local nv = `nv' - 1
* --------------------------------
* write to screen & file as required
* --------------------------------
tempfile TF
if `"`using'"' == "" local using "`TF'"
tempname WB
file open `WB' using `"`using'"' , write `replace' `append'
if "`nolist'" == "" {
file write `WB' "list( "
di as res "list( " _continue
}
* rows and columns
if "`jags'" == "" {
file write `WB' "`name' = structure(.Data = c(" _n
di as res "`name' = structure(.Data = c("
local col = 0
forvalues i = 1 / `n' {
if `touse'[`i'] == 1 {
local v = 0
local k = 1
foreach x of varlist `varlist' {
local v = `v' + 1
local y = `x'[`i']
local col = `col' + 1
if "`y'" == "." {
file write `WB' `sf`k'' ("NA")
di as res `sf`k'' ("NA") _continue
}
else {
file write `WB' `f`k'' (`y')
di as res `f`k'' (`y') _continue
}
if `i' == `last' & `v' == `nv' {
file write `WB' "),.Dim = c(`count',`nv')) "
di as res "),.Dim = c(`count',`nv')) " _continue
if "`nolist'" == "" {
file write `WB' " ) "
di as res " ) " _continue
}
}
else {
file write `WB' ","
di as res "," _continue
if `col' == `linesize' {
file write `WB' _n
di as res " "
local col = 0
}
}
local k = `k' + 1
if `k' > `nf' {
local k = 1
}
}
}
}
}
else {
* columns and rows
file write `WB' `""`name'" <- structure(c("' _n
di as res `""`name'" <- structure(c("'
local col = 0
local v = 0
local k = 1
foreach x of varlist `varlist' {
local v = `v' + 1
forvalues i = 1 / `n' {
if `touse'[`i'] == 1 {
local y = `x'[`i']
local col = `col' + 1
if "`y'" == "." {
file write `WB' `sf`k'' ("NA")
di as res `sf`k'' ("NA") _continue
}
else {
file write `WB' `f`k'' (`y')
di as res `f`k'' (`y') _continue
}
if `i' == `last' & `v' == `nv' {
file write `WB' "),.Dim = c(`count',`nv')) " _n
di as res "),.Dim = c(`count',`nv')) "
if "`nolist'" == "" {
file write `WB' " ) "
di as res " ) "
}
}
else {
file write `WB' ","
di as res "," _continue
if `col' == `linesize' {
file write `WB' _n
di as res " "
local col = 0
}
}
}
}
local k = `k' + 1
if `k' > `nf' {
local k = 1
}
}
}
file close `WB'
end


program wb_table_v2
syntax varlist(min = 3 numeric) [using/] [if] [in] , ///
[ Name(string) ///
Linesize(integer 10) ///
Formats(string) ///
Statistic(string) ///
NOLIST ///
ZERO ///
REPLACE ///
APPEND ///
JAGS ///
FORCE ]
version 8.2
marksample touse , novarlist
if "`statistic'" == "" local statistic "sum"
local i = 0
local n = 1
foreach v of varlist `varlist' {
local ++i
if `i' == 1 local FREQ "`v'"
else {
local j = `i' - 1
local V`j' "`v'"
qui su `v' if `touse'
local DIM`j' = r(max)
local n = `n' * `DIM`j''
}
}
if `n' > 1000 & "`force'" == "" {
di "Table size would be `n'. Use force option"
exit(0)
}
local NDIM = `j'
if "`name'" == "" local name "`FREQ'"
* --------------------------------
* organise the formatting
* --------------------------------
if "`formats'" == "" {
local f1 = "%8.3f"
local sf1 = "%8s"
local nf = 1
}
else {
tokenize "`formats'"
local nf = 1
while "``nf''" != "" {
local f`nf' = "``nf''"
local np = index("``nf''" , ".")
local sp = substr("``nf''" , 2 , `np'-2)
local sf`nf' = "%`sp's"
local nf = `nf' + 1
}
local nf = `nf' - 1
}
* --------------------------------
* display to screen
* --------------------------------
if "`nolist'" == "" {
di as res "list( " _continue
}
di as res "`name' = structure(.Data = c("
local col = 0
forvalues d = 1/`NDIM' {
local i`d' = 1
}
forvalues i = 1 / `n' {
local ++col
local test "`V1' == `i1'"
forvalues d = 2/`NDIM' {
local test "`test' & `V`d'' == `i`d''"
}
qui su `FREQ' if `test' & `touse'
local VALUE = r(`statistic')
if "`VALUE'" == "." {
if "`zero'" != "" di as res `sf`k'' "NA" _continue
else di as res `sf`k'' 0 _continue
}
else {
di as res `f`k'' `VALUE' _continue
}
di as res "," _continue
if `col' == `linesize' {
di as res " "
local col = 0
}
local j = `NDIM'
local done = 0
while `done' == 0 {
local i`j' = `i`j'' + 1
if `i`j'' > `DIM`j'' {
local i`j' = 1
local --j
}
else local done = 1
if `j' == 0 local done = 1
}
}
local dimc "`DIM1'"
forvalues j = 2/`NDIM' {
local dimc "`dimc',`DIM`j''"
}
di as res "),.Dim = c(`dimc'))" _continue
if "`nolist'" == "" {
di as res " )"
}
else {
di as res " "
}
end


program wb_vector_v2
syntax varlist(min = 1 numeric) [using/] [if] [in] , ///
[ Linesize(integer 10) ///
Formats(string) ///
Names(string) ///
REPLACE ///
APPEND ///
JAGS ///
NOLIST ]
version 8.2
if "`jags'" == "" {
local assign "="
local qname ""
local endwith ","
}
else {
local assign "<-"
local qname `"""'
local endwith ""
}
marksample touse , novarlist
tempvar ntouse
qui gen `ntouse' = _n * `touse'
qui summ `ntouse'
local last = r(max)
local n = _N
* --------------------------------
* organise formatting
* --------------------------------
if "`formats'" == "" {
local f1 = "%8.3f"
local sf1 = "%8s"
local nf = 1
}
else {
tokenize "`formats'"
local nf = 1
while "``nf''" != "" {
local f`nf' = "``nf''"
local np = index("``nf''" , ".")
local sp = substr("``nf''" , 2 , `np'-2)
local sf`nf' = "%`sp's"
local nf = `nf' + 1
}
local nf = `nf' - 1
}
* --------------------------------
* count variables
* --------------------------------
tokenize "`varlist'"
local nv = 1
while "``nv''" != "" {
local nv = `nv' + 1
}
local nv = `nv' - 1
* -------------------------------
* variable names
* -------------------------------
if "`names'" == "" {
local k = 1
foreach x of varlist `varlist' {
local name`k' "`x'"
local k = `k' + 1
}
}
else {
tokenize "`names'"
local k = 1
while "``k''" != "" {
local name`k' "``k''"
local k = `k' + 1
}
local --k
if `k' ! = `nv' {
di as err "Wrong number of names"
exit
}
}
* --------------------------------
* write to file if required.
* --------------------------------
tempfile TF
if `"`using'"' == "" local using "`TF'"
tempname WB
file open `WB' using `using' , write `replace' `append'
if "`nolist'" == "" {
file write `WB' "list( "
di as res "list( " _continue
}
local c = 0
local k = 1
foreach x of varlist `varlist' {
local c = `c' + 1
file write `WB' `"`qname'`name`c''`qname' `assign' c("'
di `"`qname'`name`c''`qname' `assign' c("' _continue
local line = 0
forvalues i = 1 / `n' {
if `touse'[`i'] == 1 {
local line = `line' + 1
local y = `x'[`i']
if "`y'" == "." {
file write `WB' `sf`k'' ("NA")
di as res `sf`k'' ("NA") _continue
}
else {
file write `WB' `f`k'' (`y')
di as res `f`k'' (`y') _continue
}
if `i' == `last' {
file write `WB' ") `endwith'" _n
di as res ") `endwith'"
}
else {
file write `WB' ","
di "," _continue
if mod(`line' , `linesize') == 0 {
file write `WB' _n
di as res " "
}
}
}
}
local k = `k' + 1
if `k' > `nf' {
local k = 1
}
}
if "`nolist'" == "" {
file write `WB' ")" _n
di as res ")" _n
}
file close `WB'
end
