*============================================================================
* wbsscript_v2: write a WiNBUGS script file modified for JAGS
* Author: John Thompson
* Date: Nov 2014
*============================================================================
version 12.1
program wbsscript_v2
syntax [using/] , ///
Modelfile(string) ///
[ ///
Datafile(string) ///
Initsfile(string) ///
Codafile(string) ///
Set(string) ///
Thin(integer 1) ///
DIC ///
Burnin(integer 0) ///
Updates(integer 1000) ///
SEED(integer 1) ///
OVERRELAX ///
NOQuit ///
Path(string) ///
Logfile(string) ///
Openbugs ///
Jags ///
REPLACE ]
if "`c(os)'" == "unix" local openbugs "openbugs"
if "`path'" == "" local path "`c(pwd)'"
local path = subinstr(`"`path'"',"\","/",.)
if length(`"`path'"') > 0 {
if substr(`"`path'"',length(`"`path'"'),1) != "/" {
local path `"`path'/"'
}
}
local datafile = subinstr(`"`datafile'"',"\","/",.)
local initsfile = subinstr(`"`initsfile'"',"\","/",.)
local modelfile = subinstr(`"`modelfile'"',"\","/",.)
local codafile = subinstr(`"`codafile'"',"\","/",.)
local logfile = subinstr(`"`logfile'"',"\","/",.)
local quote = char(39)
* ----------------------------------
* Mulitple init files
* ----------------------------------
tokenize `"`initsfile'"' , parse("+")
local p = 1
local nc = 0
while `"``p''"' != "" {
local p = `p' + 2
local ++nc
}
* ----------------------------------
* ORIGINAL WINBUGS
* ----------------------------------
if "`openbugs'" == "" & "`jags'" == "" {
local CmdCheck "check"
local CmdData "data"
local CmdCompile "compile"
local CmdInits "inits"
local CmdGeninit "gen.inits"
local CmdRelax "over.relax"
local CmdBlock "blockfe"
local CmdUpdate "update"
local CmdSet "set"
local CmdThin "thin.samples"
local CmdDICset "dic.set"
local CmdDICstat "dic.stats"
local CmdCoda "coda"
local CmdSave "save"
local CmdQuit "quit"
* ----------------------------------
* write to file if needed
* ----------------------------------
tempfile TF
if `"`using'"' == "" local using "`TF'"
tempname WB
file open `WB' using `"`using'"' , write `replace'
file write `WB' "display(`quote'log`quote')" _n
di "display(`quote'log`quote')"
if strpos("`modelfile'","/") == 0 local modelfile "`path'`modelfile'"
file write `WB' `"`CmdCheck'(`quote'`modelfile'`quote')"' _n
di `"`CmdCheck'(`quote'`modelfile'`quote')"'
* ----------------------------------
* several data files
* ----------------------------------
tokenize `"`datafile'"' , parse("+")
local p = 1
while `"``p''"' != "" {
if strpos("``p''","/") == 0 local `p' "`path'``p''"
file write `WB' `"`CmdData'(`quote'``p''`quote')"' _n
di `"`CmdData'(`quote'``p''`quote')"'
local p = `p' + 2
}
* ----------------------------------
* several nc
* ----------------------------------
if `nc' > 1 {
file write `WB' "`CmdCompile'(`nc')" _n
di "`CmdCompile'(`nc')"
tokenize `"`initsfile'"' , parse("+")
local p = 1
local i = 0
while `"``p''"' ! = "" {
local ++i
if strpos("``p''","/") == 0 local `p' "`path'``p''"
file write `WB' `"`CmdInits'(`i',`quote'``p''`quote')"' _n
di `"`CmdInits'(`i',`quote'``p''`quote')"'
local p = `p' + 2
}
}
else {
file write `WB' "`CmdCompile'(1)" _n
di "`CmdCompile'(1)"
if strpos("`initsfile'","/") == 0 local initsfile "`path'`initsfile'"
file write `WB' `"`CmdInits'(1,`quote'`initsfile'`quote')"' _n
di `"`CmdInits'(1,`quote'`initsfile'`quote')"'
}
file write `WB' "`CmdGeninit'()" _n
di "`CmdGeninit'()"
if "`overrelax'" != "" {
file write `WB' "`CmdRelax'(yes)" _n
di "`CmdRelax'(yes)"
}
file write `WB' "refresh(100000)" _n
di "refresh(10000)"
if `burnin' > 0 {
file write `WB' "`CmdUpdate'(`burnin')" _n
di "`CmdUpdate'(`burnin')"
}
foreach V of local set {
file write `WB' "`CmdSet'(`quote'`V'`quote')" _n
di "`CmdSet'(`quote'`V'`quote')"
}
if `thin' > 1 {
file write `WB' "`CmdThin'(`thin')" _n
di "`CmdThin'(`thin')"
}
if "`dic'" != "" {
file write `WB' "`CmdDICset'()" _n
di "`CmdDICset'()"
}
if `updates' > 0 {
file write `WB' "`CmdUpdate'(`updates')" _n
di "`CmdUpdate'(`updates')"
}
if "`dic'" != "" {
file write `WB' "`CmdDICstat'()" _n
di "`CmdDICstat'()"
}
if "`codafile'" != "" {
if strpos("`codafile'","/") == 0 local codafile "`path'`codafile'"
file write `WB' `"`CmdCoda'(*,`quote'`codafile'`quote')"' _n
di `"`CmdCoda'(*,`quote'`codafile'`quote')"'
}
if "`logfile'" != "" {
if strpos("`logfile'","/") == 0 local logfile "`path'`logfile'"
file write `WB' `"`CmdSave'(`quote'`logfile'`quote')"' _n
di `"`CmdSave'(`quote'`logfile'`quote')"'
}
if "`noquit'" == "" {
file write `WB' "`CmdQuit'()" _n
di "`CmdQuit'()"
}
file close `WB'
}
* ----------------------------------
* OPENBUGS VERSION
* ----------------------------------
else if "`openbugs'" == "openbugs" & "`jags'" == "" {
di "OPEN"
local CmdCheck "modelCheck"
local CmdData "modelData"
local CmdCompile "modelCompile"
local CmdInits "modelInits"
local CmdGeninit "modelGenInits"
local CmdUpdate "modelUpdate"
local CmdSet "samplesSet"
local CmdSeed "modelSetRN"
local CmdThin "SamplesThin"
local CmdDICset "dicSet"
local CmdDICstat "dicStats"
local CmdCoda "samplesCoda"
local CmdSave "modelSaveLog"
local CmdQuit "modelQuit"
* ----------------------------------
* write to file if needed
* ----------------------------------
tempfile TF
if `"`using'"' == "" local using "`TF'"
tempname WB
file open `WB' using `"`using'"' , write `replace'
file write `WB' "modelDisplay(`quote'log`quote')" _n
di `"modelDisplay(`quote'log`quote')"'
if strpos("`modelfile'","/") == 0 local modelfile "`path'`modelfile'"
file write `WB' `"`CmdCheck'(`quote'`modelfile'`quote')"' _n
di `"`CmdCheck'(`quote'`modelfile'`quote')"'
* ----------------------------------
* several data files
* ----------------------------------
tokenize `"`datafile'"' , parse("+")
local p = 1
while `"``p''"' != "" {
if strpos("``p''","/") == 0 local `p' "`path'``p''"
file write `WB' `"`CmdData'(`quote'``p''`quote')"' _n
di `"`CmdData'(`quote'``p''`quote')"'
local p = `p' + 2
}
* ----------------------------------
* several nc
* ----------------------------------
file write `WB' "`CmdCompile'(`nc')" _n
di "`CmdCompile'(`nc')"
file write `WB' "`CmdSeed'(`seed')" _n
di "`CmdSeed'(`seed')"
if `nc' > 1 {
tokenize `"`initsfile'"' , parse("+")
local p = 1
local i = 0
while `"``p''"' != "" {
local ++i
if strpos("``p''","/") == 0 local `p' "`path'``p''"
file write `WB' `"`CmdInits'(`quote'``p''`quote',`i')"' _n
di `"`CmdInits'(`quote'``p''`quote',`i')"'
local p = `p' + 2
}
}
else {
if strpos("`initsfile'","/") == 0 local initsfile "`path'`initsfile'"
file write `WB' `"`CmdInits'(`quote'`initsfile'`quote',1)"' _n
di `"`CmdInits'(`quote'`initsfile'`quote',1)"'
}
file write `WB' "`CmdGeninit'()" _n
di "`CmdGeninit'()"
if `burnin' > 0 {
if "`overrelax'" != "" local extra `",1,100000,`quote'T`quote'"'
else local extra `",1,10000,`quote'F`quote'"'
file write `WB' `"`CmdUpdate'(`burnin'`extra')"' _n
di `"`CmdUpdate'(`burnin'`extra')"'
}
foreach V of local set {
file write `WB' "`CmdSet'(`quote'`V'`quote')" _n
di "`CmdSet'(`quote'`V'`quote')"
}
if "`dic'" != "" {
file write `WB' "`CmdDICset'()" _n
di "`CmdDICset'()"
}
local up = round(`updates'/`thin')
if `up' > 0 {
if "`overrelax'" != "" local extra `",100000,`quote'T`quote'"'
else local extra `",10000,`quote'F`quote'"'
file write `WB' `"`CmdUpdate'(`up',`thin'`extra')"' _n
di `"`CmdUpdate'(`up',`thin'`extra')"'
}
if "`dic'" != "" {
file write `WB' "`CmdDICstat'()" _n
di "`CmdDICstat'()"
}
if `"`codafile'"' ! = "" {
if strpos("`codafile'","/") == 0 local codafile "`path'`codafile'"
file write `WB' `"`CmdCoda'(`quote'*`quote',`quote'`codafile'`quote')"' _n
di `"`CmdCoda'(`quote'*`quote',`quote'`codafile'`quote')"'
}
if "`logfile'" != "" {
if strpos("`logfile'","/") == 0 local logfile "`path'`logfile'"
file write `WB' `"`CmdSave'(`quote'`logfile'`quote')"' _n
di `"`CmdSave'(`quote'`logfile'`quote')"'
}
if "`noquit'" == "" {
file write `WB' "`CmdQuit'('yes')" _n
di "`CmdQuit'('yes')"
}
file close `WB'
}
else if "`openbugs'" == "" & "`jags'" == "jags" {
di "JAGS"
local CmdCheck "model in"
local CmdData "data in"
local CmdCompile "compile"
local CmdInits "parameters in"
local CmdGeninit "initialize"
local CmdUpdate "update"
local CmdSet "monitor"
local CmdSeed ""
local CmdThin ""
local CmdDICset ""
local CmdDICstat ""
local CmdCoda "coda *"
local CmdSave ""
local CmdQuit "exit"
* ----------------------------------
* write to file if needed
* ----------------------------------
tempfile TF
if `"`using'"' == "" local using "`TF'"
tempname WB
file open `WB' using `"`using'"' , write `replace'
if strpos("`modelfile'","/") == 0 local modelfile "`path'`modelfile'"
file write `WB' `"`CmdCheck' `quote'`modelfile'`quote'"' _n
di `"`CmdCheck' `quote'`modelfile'`quote'"'
* ----------------------------------
* several data files
* ----------------------------------
tokenize `"`datafile'"' , parse("+")
local p = 1
while `"``p''"' != "" {
if strpos("``p''","/") == 0 local `p' "`path'``p''"
file write `WB' `"`CmdData' `quote'``p''`quote'"' _n
di `"`CmdData' `quote'``p''`quote'"'
local p = `p' + 2
}
* ----------------------------------
* several nc
* ----------------------------------
if `nc' == 1 {
file write `WB' "`CmdCompile'" _n
di "`CmdCompile'"
}
else {
file write `WB' "`CmdCompile' , nchains(`nc')" _n
di "`CmdCompile' , nchains(`nc')"
}
if `nc' > 1 {
tokenize `"`initsfile'"' , parse("+")
local p = 1
local i = 0
while `"``p''"' != "" {
local ++i
if strpos("``p''","/") == 0 local `p' "`path'``p''"
file write `WB' `"`CmdInits' `quote'``p''`quote', chain(`i')"' _n
di `"`CmdInits' `quote'``p''`quote', chain(`i')"'
local p = `p' + 2
}
}
else {
if strpos("`initsfile'","/") == 0 local initsfile "`path'`initsfile'"
file write `WB' `"`CmdInits' `quote'`initsfile'`quote'"' _n
di `"`CmdInits' `quote'`initsfile'`quote'"'
}
file write `WB' "`CmdGeninit'" _n
di "`CmdGeninit'"
if `burnin' > 0 {
file write `WB' `"`CmdUpdate' `burnin' "' _n
di `"`CmdUpdate' `burnin'"'
}
foreach V of local set {
if `thin' == 1 {
file write `WB' "`CmdSet' `V'" _n
di "`CmdSet' `V'"
}
else {
file write `WB' "`CmdSet' `V', thin(`thin')" _n
di "`CmdSet'`V', thin(`thin')"
}
}
if `updates' > 0 {
file write `WB' `"`CmdUpdate' `updates'"' _n
di `"`CmdUpdate' `updates'"'
}
if `"`codafile'"' ! = "" {
if strpos("`codafile'","/") == 0 local codafile "`path'`codafile'"
file write `WB' `"`CmdCoda' , stem(`quote'`codafile'`quote')"' _n
di `"`CmdCoda', stem(`quote'`codafile'`quote')"'
}
if "`noquit'" == "" {
file write `WB' "`CmdQuit'" _n
di "`CmdQuit'"
}
file close `WB'
}
end
