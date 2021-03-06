#' Least Absolute Shrinkage and Selection Operator
#'
#' LASSO is a popular regularization scheme in linear regression in pursuit of sparsity in coefficient vector
#' that has been widely used. The method can be used in feature selection in that given the regularization parameter,
#' it first solves the problem and takes indices of estimated coefficients with the largest magnitude as
#' meaningful features by solving
#' \deqn{\textrm{min}_{\beta} ~ \frac{1}{2}\|X\beta-y\|_2^2 + \lambda \|\beta\|_1}
#' where \eqn{y} is \code{response} in our method.
#'
#' @param X an \eqn{(n\times p)} matrix or data frame whose rows are observations
#' and columns represent independent variables.
#' @param response a length-\eqn{n} vector of response variable.
#' @param ndim an integer-valued target dimension.
#' @param preprocess an additional option for preprocessing the data.
#' Default is "null". See also \code{\link{aux.preprocess}} for more details.
#' @param ycenter a logical; \code{TRUE} to center the response variable, \code{FALSE} otherwise.
#' @param lambda sparsity regularization parameter in \eqn{(0,\infty)}.
#'
#' @return a named list containing
#' \describe{
#' \item{Y}{an \eqn{(n\times ndim)} matrix whose rows are embedded observations.}
#' \item{featidx}{a length-\eqn{ndim} vector of indices with highest scores.}
#' \item{trfinfo}{a list containing information for out-of-sample prediction.}
#' \item{projection}{a \eqn{(p\times ndim)} whose columns are basis for projection.}
#' }
#'
#' @examples
#' \donttest{
#' ## generate swiss roll with auxiliary dimensions
#' ## it follows reference example from LSIR paper.
#' n = 123
#' theta = runif(n)
#' h     = runif(n)
#' t     = (1+2*theta)*(3*pi/2)
#' X     = array(0,c(n,10))
#' X[,1] = t*cos(t)
#' X[,2] = 21*h
#' X[,3] = t*sin(t)
#' X[,4:10] = matrix(runif(7*n), nrow=n)
#'
#' ## corresponding response vector
#' y = sin(5*pi*theta)+(runif(n)*sqrt(0.1))
#'
#' ## try different regularization parameters
#' out1 = do.lasso(X, y, lambda=0.1)
#' out2 = do.lasso(X, y, lambda=1)
#' out3 = do.lasso(X, y, lambda=10)
#'
#' ## visualize
#' opar <- par(no.readonly=TRUE)
#' par(mfrow=c(1,3))
#' plot(out1$Y, main="LASSO::lambda=0.1")
#' plot(out2$Y, main="LASSO::lambda=1")
#' plot(out3$Y, main="LASSO::lambda=10")
#' par(opar)
#' }
#'
#' @references
#' \insertRef{tibshirani_regression_1996}{ADMM}
#'
#' @rdname linear_LASSO
#' @author Kisung You
#' @export
do.lasso <- function(X, response, ndim=2, preprocess=c("null","center","scale","cscale","whiten","decorrelate"),
                     ycenter=FALSE, lambda=1.0){
  #------------------------------------------------------------------------
  ## PREPROCESSING
  #   1. data matrix
  aux.typecheck(X)
  n = nrow(X)
  p = ncol(X)
  #   2. response
  response = as.double(response)
  if ((any(is.infinite(response)))||(!is.vector(response))||(any(is.na(response)))){
    stop("* do.lasso : 'response' should be a vector containing no NA values.")
  }
  #   3. ndim
  ndim = as.integer(ndim)
  if (!check_ndim(ndim,p)){stop("* do.lasso : 'ndim' is a positive integer in [1,#(covariates)).")}
  #   4. preprocess
  if (missing(preprocess)){
    algpreprocess = "null"
  } else {
    algpreprocess = match.arg(preprocess)
  }
  #   5. lambda
  lambdaval = as.double(lambda)
  if (!check_NumMM(lambdaval,0,1e+10,compact=FALSE)){stop("* do.lasso : 'lambda' should be a nonnegative real number.")}

  #------------------------------------------------------------------------
  ## COMPUTATION : DATA PREPROCESSING
  tmplist = aux.preprocess.hidden(X,type=algpreprocess,algtype="linear")
  trfinfo = tmplist$info
  pX      = tmplist$pX

  if (!is.logical(ycenter)){
    stop("* do.lasso : 'ycenter' should be a logical variable.")
  }
  if (ycenter==TRUE){
    response = response-mean(response)
  }

  #------------------------------------------------------------------------
  ## COMPUTATION : MAIN COMPUTATION FOR LASSO
  #   1. run LASSO
  runLASSO   = ADMM::admm.lasso(pX, response, lambda=lambdaval)
  #   2. take the score
  lscore     = abs(as.vector(runLASSO$x))
  #   3. select the largest ones in magnitude
  idxvec     = base::order(lscore, decreasing=TRUE)[1:ndim]
  #   4. find the projection matrix
  projection = aux.featureindicator(p,ndim,idxvec)

  #------------------------------------------------------------------------
  ## RETURN
  result = list()
  result$Y = pX%*%projection
  result$featidx = idxvec
  result$trfinfo = trfinfo
  result$projection = projection
  return(result)
}
