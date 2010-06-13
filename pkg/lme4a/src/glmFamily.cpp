#include "glmFamily.h"
#include <cmath>
#include <limits>

using namespace Rcpp;
using namespace std;

double glmFamily::epsilon = numeric_limits<double>::epsilon();
double glmFamily::INVEPS = 1. / glmFamily::epsilon;
double glmFamily::LTHRESH = 30.;
double glmFamily::MLTHRESH = -30.;

fmap glmFamily::linvs = fmap();
fmap glmFamily::lnks = fmap();
fmap glmFamily::muEtas = fmap();
fmap glmFamily::varFuncs = fmap();

glmFamily::glmFamily(SEXP ll) : lst(ll) {
    if (as<string>(lst.attr("class")) != "family")
	Rf_error("glmFamily only from list of (S3) class \"family\"");

    CharacterVector fam = lst["family"], llink = lst["link"];
    char *pt = fam[0]; family = string(pt);
    pt = llink[0]; link = string(pt);

    if (!lnks.count("identity")) { // initialize the static maps
	lnks["log"] = &log;
	muEtas["log"] = linvs["log"] = &exp;

	lnks["sqrt"] = &sqrt;
	linvs["sqrt"] = &sqrf;
	muEtas["sqrt"] = &twoxf;

	lnks["identity"] = linvs["identity"] = &identf;
	muEtas["identity"] = &onef;

	lnks["inverse"] = linvs["inverse"] = &inversef;
	muEtas["inverse"] = &invderivf;

	lnks["logit"] = &logitLink;
	linvs["logit"] = &logitLinkInv;
	muEtas["logit"] = &logitMuEta;

	lnks["probit"] = &probitLink;
	linvs["probit"] = &probitLinkInv;
	muEtas["probit"] = &probitMuEta;

	varFuncs["Gamma"] = &sqrf;             // x^2
	varFuncs["binomial"] = &x1mxf;         // x * (1 - x)
	varFuncs["inverse.gaussian"] = &cubef; // x^3
	varFuncs["gaussian"] = &onef;	       // 1
	varFuncs["poisson"] = &identf;	       // x
    }
}

void
glmFamily::linkFun(Rcpp::NumericVector &eta, Rcpp::NumericVector const &mu) {
    if (lnks.count(link)) {
	transform(mu.begin(), mu.end(), eta.begin(), lnks[link]);
    } else {
	Function linkfun = lst["linkfun"];
	NumericVector ans = linkfun(mu);
	copy(ans.begin(), ans.end(), eta.begin());
    }
}

void
glmFamily::linkInv(Rcpp::NumericVector &mu, Rcpp::NumericVector const &eta) {
    if (linvs.count(link)) {
	transform(eta.begin(), eta.end(), mu.begin(), linvs[link]);
    } else {
	Function linkinv = lst["linkinv"];
	NumericVector ans = linkinv(eta);
	copy(ans.begin(), ans.end(), mu.begin());
    }
}

Rcpp::NumericVector
glmFamily::muEta(Rcpp::NumericVector const &eta) const {
    if (muEtas.count(link)) {
	NumericVector ans(eta.size());
	transform(eta.begin(), eta.end(), ans.begin(), muEtas[link]);
	return ans;
    }
    Function mu_eta = ((const_cast<glmFamily*>(this))->lst)["mu.eta"];
    return mu_eta(eta);
}

Rcpp::NumericVector
glmFamily::variance(Rcpp::NumericVector const &mu) const {
    if (varFuncs.count(link)) {
	NumericVector ans(mu.size());
	transform(mu.begin(), mu.end(), ans.begin(), varFuncs[link]);
	return ans;
    }
    Function vv = ((const_cast<glmFamily*>(this))->lst)["variance"];
    return vv(mu);
}

Rcpp::NumericVector
glmFamily::devResid(Rcpp::NumericVector const &mu,
		    Rcpp::NumericVector const &weights,
		    Rcpp::NumericVector const &y) const {
    Function devres = ((const_cast<glmFamily*>(this))->lst)["dev.resids"];
    return devres(y, mu, weights);
}
