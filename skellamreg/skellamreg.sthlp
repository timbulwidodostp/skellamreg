{smcl}
{* *! version 1.0  16march2023}{...}
{cmd:help skellamreg}{right: ({browse "https://doi.org/10.1177/1536867X241257804":SJ24-2: st0748})}
{hline}

{marker title}{...}
{title:Title}

{p2colset 5 19 21 2}{...}
{p2col :{cmd:skellamreg} {hline 2}}Skellam regression estimator{p_end}
{p2colreset}{...}


{title:Syntax}

{pstd}
Two syntaxes are possible:


    {title:1. Declare a unique set of covariates}

{p 8 18 2}
{cmd:skellamreg} {depvar} [{indepvars}] {ifin} [{cmd:,} {it:options}]

{p 4 4 2}
The explanatory variables are assumed to be the same for the two underlying
Poisson equations.  If no explanatory variable is declared, only a constant is
considered among regressors (which brings us to the unconditional estimation of
rate parameters).


    {title:2. Declare two sets of covariates}

{p 8 18 2}
{cmd:skellamreg} {depvar} {cmd:(}{indepvars}1{cmd:)}
{cmd:(}{indepvars}2{cmd:)} {ifin} [{cmd:,} {it:options}]

{p 4 4 2}
The explanatory variables are split into two groups (delimited by parentheses)
that are not constrained to be the same.  These groups are the set of the
explanatory variables of the first and second underlying Poisson
processes.  If parentheses are left empty, only a constant is considered for
that group of variables, and the unconditional rate is considered for that
underlying Poisson process.  A variable declared without parentheses is
considered as a group.

{synoptset 23 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt robust}}compute robust standard errors of the
estimated parameters{p_end}
{synopt:{opth cluster(varname)}}compute cluster-corrected standard errors of the
estimated parameters{p_end}
{synopt:{opt nol:og}}do not show iteration logs{p_end}
{p2coldent:* {opt noc:onstant}}fit a model without constants{p_end}
{p2coldent:+ {opt stub(string)}}provide a stub for the dependent variable{p_end}
{p2coldent:- {opt t:echnique(string)}}change optimization technique; see
{manhelp optimize##i_technique M-5:optimize()}{p_end}
{synopt:{opt nod:ofcorrection}}do not correct for the degrees of freedom{p_end}
{synopt:{opt level(cilevel)}}set the confidence level{p_end}
{synoptline}
{p 4 6 2}
* This option removes the constant from both equations.  If one is interested
in having a constant in only one of the equations, a solution is to use this
option and then generate a variable equal to one and declare it among the
explanatory variables in the desired group.{p_end}
{p 4 6 2}
+ The code creates two temporary variables automatically by taking the name of
the dependent variable and adding {cmd:_count_1} and {cmd:_count_2}.  If a
different name needs to be used (for example, if a variable with the same name
already exists in the dataset), the stub option can be used to declare
it.{p_end}
{p 4 6 2}
- Note that the Nelder-Mead optimization technique is not available here.


{marker postestimation}{...}
{title:Options for predict postestimation command}

{synoptset 10}{...}
{synopthdr}
{synoptline}
{synopt:{opt ndiff}}generate predicted difference in counts between processes (default){p_end}
{synopt:{opt xb1}}generate the linear predictions for the first process{p_end}
{synopt:{opt xb2}}generate the linear predictions for the second process{p_end}
{synopt:{opt n1}}generate predicted counts [that is, exp({cmd:xb1})] for the first process{p_end}
{synopt:{opt n2}}generate predicted counts [that is, exp({cmd:xb2})] for the second process{p_end}
{synoptline}


{title:Description}

{p 4 4 2}
{cmd:skellamreg} estimates the parameters of a Skellam distribution and
Skellam regression model using Mata's optimize function.  The dependent
variable in Skellam regression is the difference between two counts, while the
explanatory variables are predictors that may affect event frequency.


{title:Remarks}{bf}

{p 4 4 2}
This program is free software: you can redistribute it or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or any later version.

{p 4 4 2}
This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
details, see {browse "https://www.gnu.org/licenses/"}.{sf}

{p 4 4 2}
{cmd:robust} and {cmd:cluster()} options are implemented using the 
{cmd:optimize_init_cluster(}{it:S}{cmd:,} {it:c}{cmd:)} and 
{opt optimize_result_V_robust(S)} functions.


{title:Example}

{phang2}{cmd:.} {bf:{stata "set seed 1234"}}{p_end}
{phang2}{cmd:.} {bf:{stata "set obs 250"}}{p_end}
{phang2}{cmd:.} {bf:{stata "generate x=rnormal(2,1)"}}{p_end}
{phang2}{cmd:.} {bf:{stata "generate y1=rpoisson(exp(0.6*x))"}}{p_end}
{phang2}{cmd:.} {bf:{stata "generate y2=rpoisson(exp(0.4*x))"}}{p_end}
{phang2}{cmd:.} {bf:{stata "generate y=y1-y2"}}{p_end}

{pstd}
For Skellam-distributed data, {cmd:y1} and {cmd:y2} are generally not observable, and only {bf}y{sf} is observable.  However, the parameters associated with both underlying Poisson processes are estimated.{p_end}

{pstd}
If both {bf}y1{sf} and {bf}y2{sf} are observable, bivariate count regression
models can be used (see, for example, {helpb bivcnto}, if installed, by Xu and
Hardin [2016]),

{phang2}{cmd:.} {bf:{stata "skellamreg y x, stub(a)"}}{p_end}
{phang2}{cmd:.} {bf:{stata "margins, dydx(*)"}}{p_end}

{pstd}
which should be the same as{p_end}

{phang2}{cmd:.} {bf:{stata "margins, dydx(*) expression(predict(n1)-predict(n2))"}}{p_end}

{pstd}
and the same as{p_end}

{phang2}{cmd:.} {bf:{stata "margins, dydx(*) expression(exp(predict(xb1))-exp(predict(xb2)))"}}{p_end}


{title:Stored results}

{pstd}
{cmd:skellamreg} stores the following in {cmd:e()}:

{synoptset 23 tabbed}{...}
{p2col 5 23 26 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(ll)}}log likelihood{p_end}

{p2col 5 23 26 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:skellamreg}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}
{synopt:{cmd:e(title)}}title in estimation output{p_end}
{synopt:{cmd:e(properties)}}{cmd:b V}{p_end}
{synopt:{cmd:e(predict)}}program used to implement {cmd:predict}{p_end}

{p2col 5 23 26 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficient vector{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix of the estimators{p_end}

{p2col 5 23 26 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}


{title:Acknowledgment}

{p 4 4 2}
We thank Jean-Pierre Moreau, who gave us permission to use his C++ codes on
Bessel functions almost verbatim in Stata and Mata.


{title:References}

{phang}
Moreau, J-P. 2011. Program to calculate the first kind modified Bessel
function of integer order N, for any real X, using the function BESSI(N,X).

{phang}
Skellam, J. G. 1946. The frequency distribution of the difference between two
Poisson variates belonging to different populations.
{it:Journal of the Royal Statistical Society}, A ser., 109: 296.
{browse "https://doi.org/10.2307/2981372"}.

{phang} 
Xu, X. and J. W. Hardin. 2016. Regression models for bivariate count
outcomes. {it:Stata Journal} 16: 301-315.
{browse "https://doi.org/10.1177/1536867X1601600203"}


{title:Authors}

{pstd}Vincenzo Verardi{p_end}
{pstd}CRED, DEFIPP, FNRS{p_end}
{pstd}University of Namur{p_end}
{pstd}Namur, Belgium{p_end}
{pstd}vincenzo.verardi@unamur.be{p_end}

{pstd}Catherine Vermandele{p_end}
{pstd}LMTD{p_end}
{pstd}Universit{c e'} libre de Bruxelles{p_end}
{pstd}Brussels, Belgium{p_end}
{pstd}catherine.vermandele@ulb.be{p_end}


{marker alsosee}{...}
{title:Also see}

{p 4 14 2}
Article:  {it:Stata Journal}, volume 24, number 2: {browse "https://doi.org/10.1177/1536867X241257804":st0748}{p_end}

{p 7 14 2}
Help:  {manhelp poisson R}, {helpb bivcnto} (if installed){p_end}
