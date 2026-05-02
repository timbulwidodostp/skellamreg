
*! version 1.2, 13 November 2023
*! Authors: Catherine Vermandele and Vincenzo Verardi

* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.

* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
* GNU General Public License for more details.

* GNU General Public License is available at <http://www.gnu.org/licenses/>.


program define skellamreg, eclass

	version 15.0
	if replay()&"`e(cmd)'"=="skellamreg" {
		ereturn  display
		exit
	}
	

	local cmd "`0'"
	if "`cmd'"=="" {
		di in r "invalid syntax - no variables have been declared"	
		exit 132
	}
	gettoken a b : 0, parse(",")

	local pr=strpos("`a'", "(")!=0

	local c=subinstr("`a'","(","", .)
	local d=subinstr("`a'",")","", .)

	local par1=strlen("`a'")-strlen("`c'")
	local par2=strlen("`a'")-strlen("`d'")

	if (`par1'-`par2')!=0 {
		di in r "parentheses unablences"	
		exit 132
	}

	gettoken dv exp : a, parse(" ()") match(paren)

	local expsp=subinstr("`exp'","("," ",.)
	local expsp=subinstr("`expsp'",")"," ",.)
	local stp=0
	if `: list dv in expsp' local stp=1

	if `stp'!=0 {
		di in r "Dependent variable `dv' cannot be included among the explanatory variables"
		exit 198
	}

	gettoken exp1 exp2 : exp, match(paren) 
	gettoken exp2 exp3: exp2, match(paren)

	local exp3=subinstr("`exp3'"," ","", .)

	if "`exp3'" !=""&"`pr'"!="0" {
		di in r "Only two sets of explanatory variables can be provided"	
		exit 198
	}

	syntax varlist(numeric fv) [if] [in], [NOLog NOConstant stub(string) cluster(varname) robust ///
		Technique(string) NODofcorrection level(cilevel)]



	tempvar touse
	tempname b0_skelreg_001 VO_skelreg_001 b0_skelreg_002 VO_skelreg_002 ll

	*preserve

	mark `touse' `if' `in'
	markout `touse' `varlist' 

	local level0=$S_level
	set level `level'

	if `pr'==0 {
		local dv: word 1 of `varlist'
		local exp1: list varlist -dv
		local exp2: list varlist -dv
	}

	if ("`exp1'"==""|"`exp2'"=="")&"`noconstant'"!="" {
		di in red "noconstant can be used only of explanatory variables are declared for both underluing equations"
		exit(110)
	}
	*Generate fake dependent variables

	if "`stub'"==""{

		capture confirm variable `dv'_count_1
		if !_rc {
			di in red "variable `dv'_count_1 already exists in the dataset, please use stub() option"
			exit(110)
		}

		capture confirm variable `dv'_count_2
		if !_rc {
			di in red "variable `dv'_count_2 already exists in the dataset, please use stub() option"
			exit(110)
		}

		qui gen `dv'_count_1=`dv'
		qui drawnorm `dv'_count_2
		*Run a fake SURE to have access to the output table
		capture qui sureg (`dv'_count_1 `exp1', `noconstant') (`dv'_count_2 `exp2', `noconstant')  if `touse', noh

		if _rc!=0 {
		drop `dv'_count_1 `dv'_count_2
		}

		else drop `dv'_count_1 `dv'_count_2

	}

	else {
		qui gen `stub'1=`dv'
		qui drawnorm `stub'2
		*Run a fake SURE to have access to the output table
		capture qui sureg (`stub'1 `exp1', `noconstant') (`stub'2 `exp2', `noconstant')  if `touse', noh
		drop `stub'1 `stub'2
	}

	if "`technique'"=="nm" {
		di in red "the Nelder-Mead optimization technique has not been made available in skelreg"
		exit(110)
	}

	*qui keep if e(sample)
	tempvar touse
	qui gen `touse'=e(sample)
	local N=e(N)
	matrix b=e(b)
	matrix V=e(V)
	_ms_omit_info e(b)
	matrix bto = r(omit)

	* Following block comes from David Drukker (2016):
	* https://blog.stata.com/2016/02/09/programming-an-estimation-command-in-stata-handling-factor-variables-in-optimize/

	mata {
		mo_skelreg_001 = st_matrix("bto")
		ko_skelreg_001 = sum(mo_skelreg_001)
		p_skelreg_001  = cols(mo_skelreg_001)
		if (ko_skelreg_001>0) {
			Ct_skelreg_001   = J(0, p_skelreg_001, .)
			for(j_skelreg_001=1; j_skelreg_001<=p_skelreg_001; j_skelreg_001++) {
				if (mo_skelreg_001[j_skelreg_001]==1) {
					Ct_skelreg_001  = Ct_skelreg_001 \ e(j_skelreg_001, p_skelreg_001)
				}
			}
			Ct_skelreg_001 = Ct_skelreg_001, J(ko_skelreg_001, 1, 0)
		}
		else {
			Ct_skelreg_001 = J(0,p_skelreg_001+1,.)
		}

	}

	ereturn post b V , esample(`touse') depname(`dv') buildfvinfo

	ereturn scalar N= `N'
	tempvar touse
	qui gen `touse'=e(sample)
	mata: st_view(y_skelreg_001=.,.,tokens("`dv'"),"`touse'")
	mata: st_view(X1_skelreg_001=.,.,tokens("`exp1'"),"`touse'")
	mata: st_view(X2_skelreg_001=.,.,tokens("`exp2'"),"`touse'")
	mata: st_view(cluster_skelreg_001=.,.,tokens("`cluster'"),"`touse'")

	if "`noconstant'"=="" {
		mata: X1_skelreg_001=(X1_skelreg_001,J(rows(X1_skelreg_001),1,1))
		mata: X2_skelreg_001=(X2_skelreg_001,J(rows(X2_skelreg_001),1,1))
	}

	mata: S_skelreg_001=optimize_init()
	mata: optimize_init_constraints(S_skelreg_001, Ct_skelreg_001)
	if "`cluster'"!="" {
		mata: optimize_init_cluster(S_skelreg_001,cluster_skelreg_001)
	}

	mata: optimize_init_evaluator(S_skelreg_001,&crit())
	mata: optimize_init_evaluatortype(S_skelreg_001,"gf2")
	mata: optimize_init_params(S_skelreg_001,J(1,cols(X1_skelreg_001)+cols(X2_skelreg_001),0))

	if "`technique'"=="" {
		local technique="nr"
	}

	///mata: optimize_init_nmsimplexdeltas(S_skelreg_001,(1))
	mata: optimize_init_technique(S_skelreg_001, "`technique'")
	mata: optimize_init_argument(S_skelreg_001,1,y_skelreg_001)
	mata: optimize_init_argument(S_skelreg_001,2,X1_skelreg_001)
	mata: optimize_init_argument(S_skelreg_001,3,X2_skelreg_001)
	mata: optimize_init_singularHmethod(S_skelreg_001,"hybrid")


	if "`nolog'"!="" {
		noi di ""
		qui mata: b0_skelreg_001=optimize(S_skelreg_001)	
	}

	else {
		noi di ""
		noi mata: b0_skelreg_001=optimize(S_skelreg_001)	
	}


	if "`robust'"!=""{
		mata: VO_skelreg_001=optimize_result_V_robust(S_skelreg_001)
	}

	else if "`cluster'"!=""{
		mata: VO_skelreg_001=optimize_result_V_robust(S_skelreg_001)
	}

	else {
		mata: VO_skelreg_001=optimize_result_V(S_skelreg_001)
	}

	if "`nodofcorrection'"=="" {
		mata: VO_skelreg_001=VO_skelreg_001*rows(X1_skelreg_001)/(rows(X1_skelreg_001)-(cols(X1_skelreg_001)+cols(X2_skelreg_001)))
	}

	mata: nv_skelreg_001=cols(b0_skelreg_001)/2

	///mata: score=optimize_result_scores(S_skelreg_001)
	mata: st_matrix("`b0_skelreg_001'",b0_skelreg_001)
	mata: st_matrix("`VO_skelreg_001'",VO_skelreg_001)

	matrix repost b=`b0_skelreg_001'
	matrix repost V=`VO_skelreg_001'

	di in green "{col 55} Number of obs =" in yellow %8.0f `N'
	if "`cluster'"!="" {
		qui tab `cluster' if e(sample)
		local nc=r(r)
		ereturn scalar N_clust=`nc'
		di ""

		di in g "(Std. err. adjusted for" in y " `nc' " in g "clusters in" in y " `cluster'" in g ")"
	}

	if "`robust'"!="" {
		di ""
		di in g "(Std. err. are robust to heteroskedasticity)"
	}

	mata: ll_skelreg_001=optimize_result_value(S_skelreg_001)
	mata: st_local("ll", strofreal(ll_skelreg_001))
	noi di "Log likelihood = " `ll'

	ereturn display

	ereturn local  predict "skellamreg_p"
	ereturn local  title "Skellam regression"
	ereturn local  cmdline "skellamreg `cmd'"
	eret local cmd "skellamreg"

	eret scalar ll=`ll'
	set level `level0'

	{
		capture mata: mata drop BesselI()
		capture mata: mata drop crit()
		capture mata: mata drop Ct_skelreg_001
		capture mata: mata drop S_skelreg_001
		capture mata: mata drop VO_skelreg_001
		capture mata: mata drop X1_skelreg_001
		capture mata: mata drop X2_skelreg_001
		capture mata: mata drop b0_skelreg_001
		capture mata: mata drop j_skelreg_001
		capture mata: mata drop ko_skelreg_001
		capture mata: mata drop mo_skelreg_001
		capture mata: mata drop p_skelreg_001
		capture mata: mata drop y_skelreg_001
		capture mata: mata drop cluster_skelreg_001
		capture mata: mata drop nv_skelreg_001
		capture mata: mata drop ll_skelreg_001
	}

end



mata:
	/* 

		   Mata function BesselI() is a modest modification of J-P Moreau's C++ code (used with permission). The function is nearly identical to the original, with the exception of minor adjustments to make it suitable to mata vectors.

		   Comments made by J-P Moreaux in the original C++ code 	are here below
		   ***********************************************************************

		   Program to calculate the first kind modified Bessel function of integer order N, for any REAL X1_skelreg_001, using the function BesselI(N,X1_skelreg_001).

		   SAMPLE RUN: (Calculate Bessel function for N=2, X1_skelreg_001=0.75). 

		   Bessel function of order 2 for X1_skelreg_001 = 0.7500: Y = 0.073667 
		   Reference: From Numath Library By Tuan Dang Trong in Fortran 77. 

		   C++ Release 1.1 By J-P Moreau, Paris. (www.jpmoreau.fr)

		   Version 1.1: corected value of P4 in BesselIO (P4=1.2067492 and not 1.2067429) Aug. 2011. 

		   -----------------------------------------------------------------------

		   This subroutine calculates the first kind modified Bessel function
		   of integer order N, for any REAL X1_skelreg_001. We use here the classical
		   recursion formula, when X1_skelreg_001 > N. For X1_skelreg_001 < N, the Miller's algorithm
		   is used to avoid overflows. 
		   REFERENCE:
		   C.W.CLENSHAW, CHEBYSHEV SERIES FOR MATHEMATICAL FUNCTIONS,
		   MATHEMATICAL TABLES, VOL.5, 1962.

		   ***********************************************************************
	*/

	function BesselI(N,X1_skelreg_001) {
		P1=1.0; P2=3.5156229; P3=3.0899424; P4=1.2067492;
		P5=0.2659732; P6=0.360768e-1; P7=0.45813e-2;
		Q1=0.39894228; Q2=0.1328592e-1; Q3=0.225319e-2;
		Q4=-0.157565e-2; Q5=0.916281e-2; Q6=-0.2057706e-1;
		Q7=0.2635537e-1; Q8=-0.1647633e-1; Q9=0.392377e-2;
		Y1=(X1_skelreg_001:/3.75):^2;Y2=3.75:/abs(X1_skelreg_001);
		Z1=(P1:+Y1:*(P2:+Y1:*(P3:+Y1:*(P4:+Y1:*(P5:+Y1:*(P6:+Y1:*P7))))))
		Z2=Q1:+Y2:*(Q2:+Y2:*(Q3:+Y2:*(Q4:+Y2:*(Q5:+Y2:*(Q6:+Y2:*(Q7:+Y2:*(Q8:+Y2:*Q9)))))))
		Z2=Z2:*exp(abs(X1_skelreg_001)):/sqrt(abs(X1_skelreg_001))

		B0=(abs(X1_skelreg_001):<3.75):*Z1:+(abs(X1_skelreg_001):>=3.75):*Z2

		P1=0.5; P2=0.87890594; P3=0.51498869; P4=0.15084934;
		P5=0.2658733e-1; P6=0.301532e-2; P7=0.32411e-3;
		Q1=0.39894228; Q2=-0.3988024e-1; Q3=-0.362018e-2;
		Q4=0.163801e-2; Q5=-0.1031555e-1; Q6=0.2282967e-1;
		Q7=-0.2895312e-1; Q8=0.1787654e-1; Q9=-0.420059e-2;
		Z1=X1_skelreg_001:*(P1:+Y1:*(P2:+Y1:*(P3:+Y1:*(P4:+Y1:*(P5:+Y1:*(P6:+Y1:*P7))))));
		Z2=exp(abs(X1_skelreg_001)):/sqrt(abs(X1_skelreg_001))
		Z2=Z2:*(Q1:+Y2:*(Q2:+Y2:*(Q3:+Y2:*(Q4:+Y2:*(Q5:+Y2:*(Q6:+Y2:*(Q7:+Y2:*(Q8:+Y2:*Q9))))))))

		B1=(abs(X1_skelreg_001):<3.75):*Z1:+(abs(X1_skelreg_001):>=3.75):*Z2

		IACC=40;BIGNO = 1e10; BIGNI = 1e-10; TOX =2.0:/X1_skelreg_001; 
		B=BIM=BIP=BSI=J(rows(X1_skelreg_001),1,0);BI=J(rows(X1_skelreg_001),1,1);

		for (i=1;i<=rows(N);i++) {
			MJ= (2*((N[i]+floor(sqrt(IACC*N[i])))))
			for (J = MJ; J>0; J--) {
				BIM[i]=BIP[i]:+J:*TOX[i]:*BI[i];
				BIP[i]=BI[i];
				BI[i]=BIM[i];

				if (abs(BI[i]) > BIGNO) {
					BI[i]  = BI[i]*BIGNI;
					BIP[i] = BIP[i]*BIGNI;
					BSI[i] = BSI[i]*BIGNI;
				}

				if (J==N[i])  BSI[i] = BIP[i];
			}

			B[i]=BSI[i]:*B0[i]:/BI[i]
			///if (N[i]==0&X1_skelreg_001==0) B[i]=1
				///if (N[i]==0&X1_skelreg_001!=0) B[i]=B0[i]
				///if (N[i]==1) B[i]=B1[i]
				///if (N[i]!=0&X1_skelreg_001==0) B[i]=0

			if (N[i]==0) B[i]=B0[i]
			if (N[i]==1) B[i]=B1[i]
			if (X1_skelreg_001[i]==0) B[i]=0
			if (N[i]==0&X1_skelreg_001[i]==0) B[i]=1
		}

		return (B)
	}

end
mata:
	void crit(todo,b,y_skelreg_001,X1_skelreg_001,X2_skelreg_001,crit,g,H)
	{
		l1=X1_skelreg_001*b[1..cols(X1_skelreg_001)]'; 
		l2=X2_skelreg_001*b[cols(X1_skelreg_001)+1..cols(b)]'; nu=y_skelreg_001;
		ell=exp(l1+l2); absnu=abs(nu); 


		H0=J((cols(X1_skelreg_001)+cols(X2_skelreg_001)),(cols(X1_skelreg_001)+cols(X2_skelreg_001)),0);

		Iv=BesselI(absnu,2*sqrt(ell))

		Ip=BesselI(absnu:+1,2*sqrt(ell)); Ipp=BesselI(absnu:+2,2*sqrt(ell))
		Im=BesselI(abs(absnu:-1),2*sqrt(ell)); Imm=BesselI(abs(absnu:-2),2*sqrt(ell))

		p0=-(exp(l1)+exp(l2)):+0.5:*nu:*(l1-l2):+log(Iv)

		g10=(sqrt(ell):*(Ip:+Im):/(2:*Iv):-exp(l1):+0.5*nu):*X1_skelreg_001
		g20=(sqrt(ell):*(Ip:+Im):/(2:*Iv):-exp(l2):-0.5*nu):*X2_skelreg_001

		ha=ell/2+(ell/4):*((Imm:+Ipp):/Iv)
		hb=(sqrt(ell)/4):*((Im:+Ip):/Iv):*(1:-sqrt(ell):*(Im:+Ip):/Iv)
		ha=ha:+hb


		for (i=1;i<=rows(X1_skelreg_001); i++) {
			Z1=(X1_skelreg_001[i,]'*X1_skelreg_001[i,])
			Z2=(X2_skelreg_001[i,]'*X2_skelreg_001[i,])			
			Z12=(X1_skelreg_001[i,]'*X2_skelreg_001[i,])
			Z21=(X2_skelreg_001[i,]'*X1_skelreg_001[i,])
			h110=(ha[i]-exp(l1[i])):*Z1;
			h120=ha[i]:*Z12; 
			h210=ha[i]:*Z21; 
			h220=(ha[i]-exp(l2[i])):*Z2
			H0=H0+(h110,h120\h210,h220)

		}

		crit=p0

		if (todo>=1) {
			g=(g10,g20)
		}


		if (todo>=2) H=H0

	}

end

exit
