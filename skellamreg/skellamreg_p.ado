program define skellamreg_p
    version 13

    syntax newvarlist(min=1 max=1) [if] [in] , [ xb1 xb2 ndiff n1 n2]

    marksample touse, novarlist

    local nopts : word count `xb1' `xb2' `ndiff' `n1' `n2'
	local novar: word count `varlist'

    if `nopts' == 0 {
        display "(option ndiff assumed; predicted integer difference)"
    }

	tempvar p10 p20

	local v: word 1 of `varlist'

	qui _predict double `p10' if `touse', xb equation(#1)
	qui _predict double `p20' if `touse', xb equation(#2)

    if "`ndiff'" != ""|`nopts' == 0  {
		qui gen double `v'= exp(`p10')-exp(`p20')
    }

	else if "`xb1'"!=""{
		qui gen double `v'= `p10'
	}
	
	else if "`xb2'"!=""{
		qui gen double `v'= `p20'
	}
	
	else if "`n1'"!=""{
		qui gen double `v'= exp(`p10')
	}
	
	else if "`n2'"!=""{
		qui gen double `v'= exp(`p20')
	}

end
