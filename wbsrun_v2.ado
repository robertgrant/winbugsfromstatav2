*============================================================================
* wbsrun_v2: call WinBUGS from within Stata modified for JAGS
* Author: John Thompson
* Date: Nov 2014
*============================================================================
version 12.1
program wbsrun_v2 , rclass
syntax using/ , [ Executable(string) Openbugs Background Time Jags ]
if "`c(os)'" == "Unix" {
local openbugs "openbugs"
local script = subinstr(`"`using'"',"/","\",.)
if strpos("`script'","\") == 0 local script "`c(pwd)'\`script'"
}
else {
local script = subinstr(`"`using'"',"\","/",.)
if strpos("`script'","/") == 0 local script "`c(pwd)'/`script'"
}
if "`openbugs'" != "" local version "OPENBUGS"
else if "`jags'" != "" local version "JAGS"
else local version "WINBUGS"
if "`executable'" == "" {
if "`version'" == "OPENBUGS" & "`c(os)'" != "UNIX" {
local executable "OpenBUGS.exe"
}
else if "`version'" == "OPENBUGS" & "`c(os)'" == "UNIX" {
local executable "OpenBUGSCli.exe"
}
else if "`version'" == "WINBUGS" {
local executable "WinBUGS14.exe"
}
local prsdir : sysdir PERSONAL
cap confirm file `prsdir'executables.txt
if _rc == 0 {
tempname fh
file open `fh' using `prsdir'executables.txt ,read
file read `fh' inLine
local found = 0
while !r(eof) & `found' == 0 {
tokenize `"`inLine'"', parse(", ")
if upper("`1'") == "`version'" {
local executable "`3'"
local found = 1
}
file read `fh' inLine
}
file close `fh'
}
}
if "`time'" != "" {
timer clear 1
timer on 1
}
if "`c(os)'" == "Unix" {
if c(console) == "console" | "`background'" == "" {
shell "`executable'" `par' "`script'"
}
else {
winexec "`executable'" `par' "`script'"
}
}
else {
if "`background'" == "" {
if "`jags'" == "" shell "`executable'" /PAR "`script'"
else shell "`executable'" "`script'" > jagslog.txt
}
else {
winexec "`executable'" /PAR "`script'"
}
}
if "`time'" != "" {
timer off 1
qui timer list 1
di "Run time: " r(t1) "s"
return local time = r(t1)
}
end
