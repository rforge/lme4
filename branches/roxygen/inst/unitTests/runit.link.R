eps <- .Machine$double.eps
oneMeps <- 1 - eps
set.seed(1)

etas <- data.frame(A = seq.int(-8, 8, by=1),  # equal spacing to asymptotic area
                   B = runif(17, -8, 8),  # random sample from wide uniform dist
                   C = rnorm(17, 0, 8),   # random sample from wide normal dist
                   D = c(-10^30, rnorm(15, 0, 4), 10^30))

etapos <- data.frame(A = seq.int(1, 20, by=1),
                     B = rexp(20),
                     C = rgamma(20, 3),
                     D = pmax(.Machine$double.eps, rnorm(20, 2, 1)))

mubinom <-
    lapply(list(runif(100, 0, 1),
                rbeta(100, 1, 3),
                pmin(pmax(eps, rbeta(100, 0.1, 3)), oneMeps),
                pmin(pmax(eps, rbeta(100, 3, 0.1)), oneMeps)), as.numeric)

tst.lnki <- function(fam, frm) {
    ff <- glmFamily$new(family=fam)
    sapply(frm, function(x) checkEquals(fam$linkinv(x), ff$linkInv(x)))
}

tst.link <- function(fam, frm) {
    ff <- glmFamily$new(family=fam)
    sapply(frm, function(x) checkEquals(fam$linkfun(x), ff$link(x)))
}

tst.muEta <- function(fam, frm) {
    ff <- glmFamily$new(family=fam)
    sapply(frm, function(x) checkEquals(fam$mu.eta(x), ff$muEta(x)))
}

tst.variance <- function(fam, frm) {
    ff <- glmFamily$new(family=fam)
    sapply(frm, function(x) checkEquals(fam$variance(x), ff$variance(x)))
}

test.uncons.lnki <- function() {        # linkinv on unconstrained eta
    tst.lnki(binomial(), etas)          # binomial with logit link
    tst.muEta(binomial(), etas)
    tst.lnki(binomial("probit"), etas)  # binomial with probit link
    tst.muEta(binomial("probit"), etas)
    tst.lnki(binomial("cloglog"), etas) # binomial with cloglog link
    tst.muEta(binomial("cloglog"), etas)
    tst.lnki(binomial("cauchit"), etas) # binomial with cauchit link
    tst.muEta(binomial("cauchit"), etas)
    tst.lnki(poisson(), etas)           # Poisson with log link
    tst.muEta(poisson(), etas)
    tst.lnki(gaussian(), etas)          # Gaussian with identity link
    tst.muEta(gaussian(), etas)
}

test.pos.lnki <- function() {           # linkinv for positive eta
    tst.lnki(Gamma(), etapos)           # gamma family
    tst.muEta(Gamma(), etapos)
    tst.lnki(inverse.gaussian(), etapos) # inverse Gaussian
    tst.muEta(inverse.gaussian(), etapos)    
}

test.binom.link <- function() {         # link and variance for binomial mu
    tst.link(binomial(), mubinom)
    tst.variance(binomial(), mubinom)    
    tst.link(binomial("probit"), mubinom)
    tst.variance(binomial("probit"), mubinom)
    tst.link(binomial("cauchit"), mubinom)
    tst.variance(binomial("cauchit"), mubinom)
}

test.pos.link <- function() {           # link for positive mu (using positive etas)
    tst.link(poisson(), etapos)
    tst.variance(poisson(), etapos)    
    tst.link(Gamma(), etapos)
    tst.variance(Gamma(), etapos) 
    tst.link(inverse.gaussian(), etapos)
    tst.variance(inverse.gaussian(), etapos)    
}

test.uncons.link <- function() {        # link for unconstrained mu (using unconstrained etas)
    tst.link(gaussian(), etas)
    tst.variance(gaussian(), etas)    
}





