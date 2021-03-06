library(lme4a)
set.seed(101)
d <- expand.grid(block=LETTERS[1:26],rep=1:100)
d$x <- runif(nrow(d))
reff_f <- rnorm(length(levels(d$block)),sd=1)
## need intercept large enough to avoid negative values
d$eta0 <- 4+3*d$x  ## version without random effects
d$eta <- d$eta0+reff_f[d$block]
## inverse link
d$mu <- 1/d$eta
d$y <- rgamma(nrow(d),scale=d$mu/2,shape=2)

if(FALSE)## FIXME!
try(gm1 <- glmer(y ~ 1 + (1|block), d, Gamma, verbose=TRUE)) # should throw an error but not segfault
## 2011-08-23 (MM): But it *does* kill R now
## terminate called after throwing an instance of 'std::range_error'
##   what():  non-finite objective values not allowed
