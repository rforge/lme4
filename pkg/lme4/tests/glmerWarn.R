library(lme4)
library(testthat)

m3 <- glmer(Reaction ~ Days + (Days|Subject), sleepstudy)
m4 <- lmer(Reaction ~ Days + (Days|Subject), sleepstudy)
m5 <- glmer(Reaction ~ Days + (Days|Subject), sleepstudy, family=gaussian)
expect_equal(fixef(m3),fixef(m5))
expect_equal(m3,m4)
isTRUE(all.equal(m3,m5))

## would like m3==m5 != m4 ??
VarCorr(m4)
VarCorr(m5)  ## wrong??? is this the report or the
getME(m4,"theta")
getME(m5,"theta")
