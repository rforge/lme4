###################################################
### chunk number 1: preliminaries
###################################################
#line 17 "/home/bates/Documents/slides/2011-03-16-Amsterdam/3Profiling.Rnw"
options(width=65,show.signif.stars=FALSE,str=strOptions(strict.width="cut"))
library(lattice)
library(Matrix)
library(MatrixModels)
library(Rcpp)
library(minqa)
library(lme4a)
#lattice.options(default.theme = function() standard.theme())
lattice.options(default.theme = function() standard.theme(color=FALSE))
if (file.exists("classroom.rda")) {
    load("classroom.rda")
} else {
    classroom <- within(read.csv("http://www-personal.umich.edu/~bwest/classroom.csv"),
                    {
                        classid <- factor(classid)
                        schoolid <- factor(schoolid)
                        sex <- factor(sex, labels = c("M","F"))
                        minority <- factor(minority, labels = c("N", "Y"))
                    })
    save(classroom, file="classroom.rda")
}
if (file.exists("pr1.rda")) {
    load("pr1.rda")
} else {
    pr1 <- profile(fm1M <- lmer(Yield ~ 1+(1|Batch), Dyestuff, REML=FALSE))
    save(pr1, fm1M, file="pr1.rda")
}
if (file.exists("pr8.rda")) {
    load("pr8.rda")
} else {
    pr8 <- profile(fm8 <- lmer(mathgain ~
           mathkind + minority + ses + (1|classid) + (1|schoolid), classroom, REML=FALSE))
    save(pr8, fm8, file="pr8.rda")
}


###################################################
### chunk number 2: pr1 eval=FALSE
###################################################
## #line 121 "/home/bates/Documents/slides/2011-03-16-Amsterdam/3Profiling.Rnw"
## pr1 <- profile(fm1M <- lmer(Yield ~ 1+(1|Batch), Dyestuff, REML=FALSE))
## xyplot(pr1, aspect=1.3)


###################################################
### chunk number 3: pr1plot
###################################################
#line 127 "/home/bates/Documents/slides/2011-03-16-Amsterdam/3Profiling.Rnw"
print(xyplot(pr1, aspect=1.3, layout=c(3,1)))


###################################################
### chunk number 4: pr1plot2show eval=FALSE
###################################################
## #line 143 "/home/bates/Documents/slides/2011-03-16-Amsterdam/3Profiling.Rnw"
## xyplot(pr1, aspect=0.7, absVal=TRUE)


###################################################
### chunk number 5: pr1plot2
###################################################
#line 148 "/home/bates/Documents/slides/2011-03-16-Amsterdam/3Profiling.Rnw"
print(xyplot(pr1, aspect=0.7, absVal=TRUE, strip=FALSE, strip.left=TRUE,layout=c(3,1)))


###################################################
### chunk number 6: confintpr1
###################################################
#line 155 "/home/bates/Documents/slides/2011-03-16-Amsterdam/3Profiling.Rnw"
confint(pr1)


###################################################
### chunk number 7: confintpr1.99
###################################################
#line 164 "/home/bates/Documents/slides/2011-03-16-Amsterdam/3Profiling.Rnw"
confint(pr1, level=0.99)


###################################################
### chunk number 8: sigmaprof
###################################################
#line 200 "/home/bates/Documents/slides/2011-03-16-Amsterdam/3Profiling.Rnw"
zeta <- sqrt(qchisq(c(0.5,0.8,0.9,0.95,0.99), 1))
zeta <- c(-rev(zeta), 0, zeta)
spl <- attr(pr1, "forward")[[2]]
endpts <- predict(attr(pr1, "backward")[[2]], zeta)$y

fr <- data.frame(zeta = rep.int(zeta, 3),
                 endpts = c(endpts, exp(endpts), exp(2*endpts)),
                 pnm = gl(3, length(zeta)))
print(xyplot(zeta ~ endpts|pnm, fr, type = "h",
             scales = list(x = list(relation = "free")),
             xlab = NULL, ylab = expression(zeta), aspect = 1.3,
             strip = strip.custom(
             factor.levels = expression(log(sigma), sigma, sigma^2)),
             panel = function(...) {
                 panel.grid(h = -1, v = -1)
                 panel.abline(h=0)
                 panel.xyplot(...)
                 ll <- current.panel.limits()$xlim
                 lims <- switch(panel.number(), ll, log(ll), log(ll)/2)
                 pr <- predict(spl, seq(lims[1], lims[2], len = 101))
                 panel.lines(switch(panel.number(),
                                    pr$x,
                                    exp(pr$x),
                                    exp(pr$x * 2)), pr$y)
             }))


###################################################
### chunk number 9: sigma1prof
###################################################
#line 243 "/home/bates/Documents/slides/2011-03-16-Amsterdam/3Profiling.Rnw"
zeta <- sqrt(qchisq(c(0.5,0.8,0.9,0.95,0.99), 1))
zeta <- c(-rev(zeta), 0, zeta)
spl <- attr(pr1, "forward")[[1]]
endpts <- predict(attr(pr1, "backward")[[1]], zeta)$y

fr <- data.frame(zeta = rep.int(zeta, 3),
                 endpts = c(log(endpts), endpts, endpts^2),
                 pnm = gl(3, length(zeta)))
## A mighty kludge here
fr[1,] <- c(NA, 1.5, 1)
fr[12,] <- c(NA, 0, 2)
print(xyplot(zeta ~ endpts|pnm, fr, type = "h",
             scales = list(x = list(relation = "free")),
             xlab = NULL, ylab = expression(zeta), aspect = 1.3,
             strip = strip.custom(
             factor.levels = expression(log(sigma[1]), sigma[1], sigma[1]^2)),
             panel = function(...) {
                 panel.grid(h = -1, v = -1)
                 panel.abline(h = 0)
                 panel.xyplot(...)
                 ll <- (current.panel.limits()$xlim)[2]
                 lims <- switch(panel.number(),
                                c(1.5, exp(ll)),
                                c(0, ll),
                                c(0, sqrt(ll)))
                 pr <- predict(spl, seq(lims[1], lims[2], len = 101))
                 panel.lines(switch(panel.number(),
                                    log(pr$x),
                                    pr$x,
                                    pr$x^2), pr$y)
             }))


###################################################
### chunk number 10: pr1dens
###################################################
#line 308 "/home/bates/Documents/slides/2011-03-16-Amsterdam/3Profiling.Rnw"
print(densityplot(pr1, layout=c(1,3), strip=FALSE, strip.left=TRUE))


###################################################
### chunk number 11: pr1pairsshow eval=FALSE
###################################################
## #line 338 "/home/bates/Documents/slides/2011-03-16-Amsterdam/3Profiling.Rnw"
## splom(pr1)


###################################################
### chunk number 12: pr1pairs
###################################################
#line 343 "/home/bates/Documents/slides/2011-03-16-Amsterdam/3Profiling.Rnw"
print(splom(pr1))


###################################################
### chunk number 13: pr8 eval=FALSE
###################################################
## #line 399 "/home/bates/Documents/slides/2011-03-16-Amsterdam/3Profiling.Rnw"
## pr8 <- profile(fm8 <- lmer(mathgain ~ mathkind + minority +
##                ses + (1|classid) + (1|schoolid), classroom, REML=FALSE))


###################################################
### chunk number 14: pr8plot
###################################################
#line 405 "/home/bates/Documents/slides/2011-03-16-Amsterdam/3Profiling.Rnw"
print(xyplot(pr8, absVal=TRUE, aspect=0.7, layout=c(4,2), strip=FALSE,
             strip.left=TRUE, skip=rep.int(c(FALSE,TRUE,FALSE),c(3,1,4))))


###################################################
### chunk number 15: pr8pairs
###################################################
#line 427 "/home/bates/Documents/slides/2011-03-16-Amsterdam/3Profiling.Rnw"
print(splom(pr8))


