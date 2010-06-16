#include "mer.h"

using namespace std;

namespace mer {
    feModule::feModule(Rcpp::S4 xp)
	: d_beta(xp.slot("beta")),
	  d_Vtr(d_beta.size()) {
    }

    void feModule::setBeta(Rcpp::NumericVector const& bbase,
			   Rcpp::NumericVector const&  incr, double step) {
	R_len_t p = d_beta.size();
	if (bbase.size() != p)
	    throw runtime_error("feModule::setBeta size mismatch of beta and bbase");
	if (p == 0) return;

	if (step == 0.) {
	    copy(bbase.begin(), bbase.end(), d_beta.begin());
	} else {
	    if (incr.size() != p)
		throw runtime_error("feModule::setBeta size mismatch of beta and incr");
	    transform(incr.begin(), incr.end(), d_beta.begin(),
			   bind2nd(multiplies<double>(), step));
	    transform(bbase.begin(), bbase.end(), d_beta.begin(),
			   d_beta.begin(), plus<double>());
	}
    }
}