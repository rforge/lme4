#include "mer.h"

using namespace Rcpp;
using namespace MatrixNs;
using namespace std;

namespace mer{

//FIXME: change d_Ut to a CHM_SP and write a separate utility to take
//sqrtXwt and a sparse matrix.
    reModule::reModule(S4 xp)
	: d_xp(       xp),
	  d_L(     S4(xp.slot("L"))),
	  d_Lambda(S4(xp.slot("Lambda"))),
	  d_Ut(    S4(xp.slot("Ut"))),
	  d_Zt(    S4(xp.slot("Zt"))),
	  d_Lind(     xp.slot("Lind")),
	  d_lower(    xp.slot("lower")),
	  d_u(        xp.slot("u")),
	  d_cu(      d_u.size()),
	  d_sqrLenU(inner_product(d_u.begin(), d_u.end(), d_u.begin(), double())) {
    }

    /** 
     * Update L, Ut and cu for new weights.
     *
     * Update Ut from Zt and sqrtXwt, then L from Lambda and Ut
     * Update cu from wtres, Lambda and Ut.
     * 
     * @param Xwt Matrix of weights for the model matrix
     * @param wtres weighted residuals
     */
    void reModule::reweight(Rcpp::NumericMatrix const&   Xwt,
			    Rcpp::NumericVector const& wtres) {
	double mone = -1., one = 1.; 
	int Wnc = Xwt.ncol();
	if (Wnc == 1) {
	    d_Ut.update(d_Zt);	// copy Zt to Ut
	    d_Ut.scale(CHOLMOD_COL, chmDn(Xwt));
	} else {
	    int n = Xwt.nrow();
	    CHM_TR tr = M_cholmod_sparse_to_triplet(&d_Zt, &c);
	    int *j = (int*)tr->j, nnz = tr->nnz;
	    double *x = (double*)tr->x, *W = Xwt.begin();
	    for (int k = 0; k < nnz; k++) {
		x[k] *= W[j[k]];
		j[k] = j[k] % n;
	    }
	    tr->ncol = (size_t)n;

	    CHM_SP sp = M_cholmod_triplet_to_sparse(tr, nnz, &c);
	    M_cholmod_free_triplet(&tr, &c);
	    d_Ut.update(*sp);
	    M_cholmod_free_sparse(&sp, &c);
	}
				// update the factor L
	CHM_SP LambdatUt = d_Lambda.crossprod(d_Ut);
	d_L.update(*LambdatUt, 1.);
	d_ldL2 = d_L.logDet2();
				// update cu
	chmDn ccu(d_cu), cwtres(wtres);
	copy(d_u.begin(), d_u.end(), d_cu.begin());
	M_cholmod_sdmult(LambdatUt, 0/*trans*/, &one, &mone, &cwtres, &ccu, &c);
	M_cholmod_free_sparse(&LambdatUt, &c);
	NumericMatrix
	    ans = d_L.solve(CHOLMOD_L, d_L.solve(CHOLMOD_P, d_cu));
	copy(ans.begin(), ans.end(), d_cu.begin());
    }

    /** 
     * Install a new value of U, either a single vector or as a
     * combination of a base, an increment and a step factor.
     * 
     * @param ubase base value of u
     * @param incr increment relative to the base
     * @param step step fraction
     */
    void reModule::setU(Rcpp::NumericVector const &ubase,
			Rcpp::NumericVector const &incr, double step) {
	int q = d_u.size();
	if (ubase.size() != q)
	    Rf_error("%s: expected %s.size() = %d, got %d",
		     "reModule::setU", "ubase", q, ubase.size());
	if (step == 0.) {
	    copy(ubase.begin(), ubase.end(), d_u.begin());
	} else {
	    if (incr.size() != q)
		Rf_error("%s: expected %s.size() = %d, got %d",
			 "reModule::setU", "incr", q, incr.size());
	    transform(incr.begin(), incr.end(), d_u.begin(),
			   bind2nd(multiplies<double>(), step));
	    transform(ubase.begin(), ubase.end(), d_u.begin(),
			   d_u.begin(), plus<double>());
	}
	d_sqrLenU = inner_product(d_u.begin(), d_u.end(),
				       d_u.begin(), double());
    }

    /** 
     * Solve for u (or the increment for u) only.
     * 
     */  
    void reModule::solveU() {
	NumericMatrix ans = d_L.solve(CHOLMOD_A, d_cu);
	setU(NumericVector(SEXP(ans)));
    }

//    void reModule::updateDcmp(Rcpp::NumericVector &cmp) const {  // Need Matrix_0.999375-42 or later
    void reModule::updateDcmp(Rcpp::NumericVector &cmp) {
	cmp["ldL2"] = d_L.logDet2();
	cmp["ussq"] = inner_product(d_u.begin(), d_u.end(),
				    d_u.begin(), double());
    }

    /** 
     * Check and install new value of theta.  Update Lambda.
     * 
     * @param nt New value of theta
     */
    void reModule::updateLambda(NumericVector const& nt) {
	if (nt.size() != d_lower.size())
	    Rf_error("%s: %s[1:%d], expected [1:%d]",
		     "updateLambda", "newtheta",
		     nt.size(), d_lower.size());
	double *th = nt.begin(), *ll = d_lower.begin();
				// check for a feasible point
	for (int i = 0; i < nt.size(); i++)
	    if (th[i] < ll[i] || !R_finite(th[i]))
		Rf_error("updateLambda: theta not in feasible region");
				// store (a copy of) theta
	d_xp.slot("theta") = clone(nt);
				// update Lambda from theta and Lind
	double *Lamx = (double*)d_Lambda.x;
	int *Li = d_Lind.begin(), Lis = d_Lind.size();
	for (int i = 0; i < Lis; i++) Lamx[i] = th[Li[i] - 1];
    }

    /** 
     * Solve for u given the updated cu
     * 
     * @param cu 
     */
    void reModule::updateU(Rcpp::NumericVector const &cu) {
	NumericMatrix nu = d_L.solve(CHOLMOD_Pt, d_L.solve(CHOLMOD_Lt, cu));
	setU(NumericVector(SEXP(nu)));
    }

    /** 
     * Zero the contents of d_u and d_sqrLenU
     */
    void reModule::zeroU() {
	fill(d_u.begin(), d_u.end(), double());
	d_sqrLenU = 0.;
    }
}