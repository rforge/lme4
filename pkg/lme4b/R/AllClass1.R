## Class definitions for the package

setClass("lmList",
         representation(call = "call",
                        pool = "logical"),
         contains = "list")

## TODO: export
setClass("lmList.confint", contains = "array")

### Environment-based classes.  These will eventually replace the
### previous classes

##' Optimization environment class.

setClass("optenv", representation(setPars = "function",
				  getPars = "function",
				  getBounds = "function"),
	 contains = "environment")


##' Basic properties of a mixed-effects representation.
##'
##' The shared environment should contain objects y, X, Zt, Ut, beta,
##' u, Lambda, Lind, theta, L and ldL2.
##'
setClass("merenv", representation("VIRTUAL"), contains = "optenv",
         validity = function(object)
     {
         rho <- env(object)
         if (!(is.numeric(y <- rho$y) &&
               (n <- length(y)) > 0))
             return("environment must contain a non-trivial numeric response y")
         if (!(is(X <- rho$X, "dMatrix") &&
               is(Zt <- rho$Zt, "dMatrix") &&
               ((N <- nrow(X)) == ncol(Zt))))
             return("environment must contain Matrix objects X and Zt with nrow(X) == ncol(Zt)")
         if (N %% n || N <= 0)
             return(sprintf("nrow(X) = %d must be a positive multiple of length(y) = %d",
                            N, n))
         p <- ncol(X)
         q <- nrow(Zt)
         if (!(is(Ut <- rho$Ut, "dMatrix") &&
               all(dim(Ut) == dim(Zt))))
             return("environment must contain Ut of same dimensions as Zt")
         if (!(is.numeric(beta <- rho$beta) && length(beta) == p))
             return(sprintf("environment must contain a numeric vector beta of length %d",
                            ncol(X)))
         if (!(is.numeric(u <- rho$u) &&
               length(u) == q))
             return(sprintf("environment must contain a numeric vector u of length %d",
                            q))
         if (!(is(Lambda <- rho$Lambda, "dMatrix") &&
               all(dim(Lambda) == q)))
             return(sprintf("environment must contain a %d by %d Matrix Lambda",
                            q, q))
         if (!(is.integer(Lind <- rho$Lind) &&
               length(Lind) == length(Lambda@x) &&
               min(Lind) == 1L))
             return(sprintf("environment must contain an integer vector Lind of length %d with minimum 1",
                            length(Lambda@x)))
         nth <- max(Lind)
         if (!(is.numeric(theta <- rho$theta) &&
               length(theta) == nth))
             return(sprintf("environment must contain a numeric vector theta of length %d",
                            nth))
         if (!(all(seq_along(theta) %in% Lind)))
             return("not all indices of theta occur in Lind")
         if (!(is(L <- rho$L, "CHMfactor") &&
               all(dim(L) == q)))
             return("environment must contain a CHMfactor L")
         TRUE
     })

##' Mixed-effects model representation based on random-effects terms
##'
##' The general merenv class does not associate components of the
##' random-effects vector, b, with particular terms in a formula.
##' In this class the random effects are associated with a set of
##' terms with grouping factors in the list flist.  The number of
##' columns in each term is available in the nc vector.
##'
setClass("merenvtrms", representation("VIRTUAL"), contains = "merenv",
         validity = function(object) .Call(merenvtrms_validate, env(object)))
     ## {
     ##     rho <- env(object)
     ##     if (!(is.list(flist <- rho$flist) &&
     ##           all(sapply(flist, is.factor))))
     ##         return("environment must contain a list of factors, flist")
     ##     flseq <- seq_along(flist)
     ##     if (!(is.integer(asgn <- attr(flist, "assign")) &&
     ##           all(flseq %in% asgn) &&
     ##           all(asgn %in% flseq)))
     ##         return("asgn attribute of flist missing or malformed")
     ##     nl <- sapply(flist, function(x) length(levels(x)))[asgn]
     ##     if (!(is.list(cnms <- rho$cnms) &&
     ##           all(sapply(cnms, is.character)) &&
     ##           all(sapply(cnms, length) > 0) &&
     ##           length(cnms) == length(asgn)))
     ##         return("list of column names, cnms, must match asgn attribute in length")
     ## })


##' Linear mixed-effects model representation.
##'
##'
##'
##'
setClass("lmerenv", contains = "merenvtrms",
         validity = function(object)
     {
         rho <- env(object)
         p <- length(rho$beta)
         q <- length(rho$u)
	 if (!(is.numeric(Utr <- rho$Utr) && length(Utr) == q))
	     return("environment must contain a numeric q-vector Utr")
	 if (!(is(UtV <- rho$UtV, "dMatrix") && all(dim(UtV) == c(q, p))))
	     return("environment must contain a q by p Matrix UtV")
	 if (!(is(RZX <- rho$RZX, "dMatrix") && all(dim(RZX) == c(q, p))))
	     return("environment must contain a q by p Matrix RZX")
	 RX <- rho$RX
	 if (is(RX, "CHMfactor")) RX <- as(RX, "sparseMatrix")
	 if (!(is(RX, "dMatrix") && all(dim(RX) == c(p, p))))
	     return("environment must contain a p by p Matrix RX")
	 if (!(is.numeric(Vtr <- rho$Vtr) && length(Vtr) == p))
	     return("environment must contain a numeric p-vector Vtr (= Xty in linear case)")
	 if (!(is(VtV <- rho$VtV, "dMatrix") &&
	       is(VtV, "symmetricMatrix") &&
	       all(dim(VtV) == c(p, p))))
	     return("environment must contain a symmetric Matrix VtV (= XtX in linear case)")
         TRUE
     })

## Either a dense _or_ sparse Cholesky factorization
setClassUnion("CholKind",
              members = c("Cholesky", "CHMfactor"))

if(is.null(getClassDef("dsymmetricMatrix"))) ## not very latest version of 'Matrix':
    ## Virtual class of numeric symmetric matrices -- new (2010-04) - for lme4
    setClass("dsymmetricMatrix", representation("VIRTUAL"),
             contains = c("dMatrix", "symmetricMatrix"))

## Some __NON-exported__ classes just for auto-validity checking:
setClassUnion("dgC_or_diMatrix", members = c("dgCMatrix", "ddiMatrix"))
setClassUnion("dsC_or_dpoMatrix", members = c("dsCMatrix", "dpoMatrix"))

### FIXME?  This is currently modelled after "old-lme4"
### ----- following  g?l?merenv, should rather have *common* slots here,
##  and also define "lmer" , "glmer" etc  *classes* with the specific slots?
## __ FIXME __
setClass("mer",
	 representation(
			env = "merenv",
			frame = "data.frame",# model frame (or empty frame)
			call = "call",	 # matched call
			sparseX = "logical",
			X = "dMatrix", # fixed effects model matrix (sparse or dense)
			## Xst = "dgCMatrix", # sparse fixed effects model matrix
			Lambda = "dgC_or_diMatrix", # ddi- or dgC-Matrix"
			Zt = "dgCMatrix",# sparse form of Z'
			ZtX = "dMatrix", # [dge- or dgC-Matrix] -- == UtV in newer classes
			Utr = "numeric", # was "dgeMatrix", related to Zty in linear case
			pWt = "numeric",# prior weights,   __ FIXME? __
			offset = "numeric", # length 0 -> no offset
			y = "numeric",	 # response vector
                                        # Gp = "integer",  # pointers to row groups of Zt

			devcomp = "list", ## list(cmp = ...,  dims = ...)
                        ## this *replaces* (?) previous 'dims' and 'deviance'
			##-- deviance = "numeric", # ML and REML deviance and components
			dims = "integer",# dimensions and indicators
			##-- dims : old-lme4's lmer(): named vector of length 18, names :
                        ## --> ../../lme4/R/lmer.R 'dimsNames' & 'dimsDefaults'
                        ## c("nt", "n", "p", "q", "s", "np", "LMM", "REML",
                        ##   "fTyp", "lTyp", "vTyp", "nest", "useSc", "nAGQ",
                        ##   "verb", "mxit", "mxfn", "cvg")

			##--- slots that vary during optimization------------

			V = "matrix",	 # gradient matrix
			Ut = "dgCMatrix", #
			L = "CHMfactor", # Cholesky factor of weighted P(.. + I)P'
			Lind = "integer",
			beta = "numeric" ,# fixed effects (length p)
			ranef = "numeric",# random effects (length q)
			u = "numeric",	 # orthogonal random effects (q)
			theta = "numeric",# parameter for Sigma or Lambda
			mu = "numeric",	 # fitted values at current beta and b
			gamma = "numeric",#  for NLME - otherwise == mu (?)
			##? resid = "numeric",# raw residuals at current beta and b
			sqrtrWt = "numeric",# sqrt of weights used with residuals
			sqrtXWt = "numeric",# sqrt of model matrix row weights
			RZX = "dMatrix", # dgeMatrix or dgCMatrix
			RX = "CholKind",  # "Cholesky" (dense) or "dCHMsimpl" (sparse)
			XtX = "dsC_or_dpoMatrix", # "dsymmetricMatrix", # dpo* or dsC* -- == VtV in newer classes
			Vtr = "numeric"
			),
	 validity = function(object) TRUE ## FIXME .Call(mer_validate, object)
	 )


setClass("summary.mer", # Additional slots in a summary object
         representation(
			methTitle = "character",
			logLik= "logLik",
			ngrps = "integer",
			sigma = "numeric", # scale, non-negative number
			coefs = "matrix",
			## vcov = "dpoMatrixorNULL", was  vcov = "dpoMatrix",
			REmat = "matrix",
			AICtab= "data.frame"),
         contains = "mer")

setClass("merTrms",
         representation(
                        flist = "data.frame", # list of grouping factors
                        cnms = "list",        # of character - column names
                        ncTrms = "integer"    # := sapply(cnms, length)
                        ),
         contains = "mer")
setClass("lmer", representation(),# <-- those that are unique to lmer() case
         contains = "merTrms")

setClass("glmer",
	 representation(# slots	 unique to glmer() :
			eta = "numeric", # unbounded predictor			- GLM
			muEta = "numeric",# d mu/d eta evaluated at current eta - GLM
			var = "numeric"	 # conditional variances of Y		- GLM
			## ghx = "numeric", # zeros of Hermite polynomial
			## ghw = "numeric", # weights used for AGQ
			),
	 contains = "merTrms")

setClass("nlmer",
	 representation(nlmodel = "call" # nonlinear model call
			),
	 contains = "merTrms")

setClass("glmerenv", contains = "merenvtrms",
         validity = function(object) {
             rho <- env(object)
             n <- length(rho$y)
             if (!(is.numeric(rho$mu) && length(rho$mu) == n))
                 return("environment must contain a numeric vector \"mu\"")
             if (!(is.numeric(rho$muEta) && length(rho$muEta) == n))
                 return("environment must contain a numeric vector \"muEta\"")
             if (!(is.numeric(rho$var) && length(rho$var) == n))
                 return("environment must contain a numeric vector \"var\"")
             if (!(is.numeric(rho$sqrtrWt) && length(rho$sqrtrWt) == n))
                 return("environment must contain a numeric vector \"sqrtrWt\"")
             if (!(is.list(family <- rho$family)))
                 return("environment must contain a list \"family\"")
             if (!(is.character(family$family) && length(family$family) == 1))
                 return("family list must contain a character variable \"family\"")
             if (!(is.character(family$link) && length(family$link) == 1))
                 return("family list must contain a character variable \"link\"")
             TRUE
         })
