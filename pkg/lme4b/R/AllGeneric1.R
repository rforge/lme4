setGeneric("lmList",
           function(formula, data, family, subset, weights,
                    na.action, offset, pool, ...)
           standardGeneric("lmList"))

## utilities, *not* exported (yet ?)
setGeneric("isREML", function(x) standardGeneric("isREML"),
	   valueClass = "logical")
setGeneric("getCall", function(x) standardGeneric("getCall"),
	   valueClass = "call")

## utilities, these *exported*:
setGeneric("getL", function(x) standardGeneric("getL"))

##' extract the deviance components
setGeneric("devcomp", function(x, ...) standardGeneric("devcomp"))

##' extract the environment associated with an object
setGeneric("env", function(x, ...) standardGeneric("env"),
           valueClass = "environment")


fixed.effects <- function(object, ...) {
    ## fixed.effects was an alternative name for fixef
    .Deprecated("fixef")
    mCall = match.call()
    mCall[[1]] = as.name("fixef")
    eval(mCall, parent.frame())
}

random.effects <- function(object, ...) {
    ## random.effects was an alternative name for ranef
    .Deprecated("ranef")
    mCall = match.call()
    mCall[[1]] = as.name("ranef")
    eval(mCall, parent.frame())
}

setGeneric("sigma", function(object, ...) standardGeneric("sigma"))
