#' Elastic Net Regularization
#'
#' Elastic Net is a regularized regression method by solving
#' \deqn{\textrm{min}_{\beta} ~ \frac{1}{2}\|X\beta-y\|_2^2 + \lambda_1 \|\beta \|_1 + \lambda_2 \|\beta \|_2^2}
#' where \eqn{y} iis \code{response} variable in our method. The method can be used in feature selection like LASSO.
#'
#' @param X an \eqn{(n\times p)} matrix or data frame whose rows are observations
#' and columns represent independent variables.
#' @param response a length-\eqn{n} vector of response variable.
#' @param ndim an integer-valued target dimension.
#' @param preprocess an additional option for preprocessing the data.
#' Default is "null". See also \code{\link{aux.preprocess}} for more details.
#' @param ycenter a logical; \code{TRUE} to center the response variable, \code{FALSE} otherwise.
#' @param lambda1 \eqn{\ell_1} regularization parameter in \eqn{(0,\infty)}.
#' @param lambda2 \eqn{\ell_2} regularization parameter in \eqn{(0,\infty)}.
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
#' out1 = do.enet(X, y, lambda1=0.1, lambda2=0.1)
#' out2 = do.enet(X, y, lambda1=1,   lambda2=0.1)
#' out3 = do.enet(X, y, lambda1=10,  lambda2=0.1)
#' out4 = do.enet(X, y, lambda1=0.1, lambda2=1)
#' out5 = do.enet(X, y, lambda1=1,   lambda2=1)
#' out6 = do.enet(X, y, lambda1=10,  lambda2=1)
#' out7 = do.enet(X, y, lambda1=0.1, lambda2=10)
#' out8 = do.enet(X, y, lambda1=1,   lambda2=10)
#' out9 = do.enet(X, y, lambda1=10,  lambda2=10)
#'
#' ## visualize
#' ## ( , ) denotes two regularization parameters
#' opar <- par(no.readonly=TRUE)
#' par(mfrow=c(3,3))
#' plot(out1$Y, main="ENET::(0.1,0.1)")
#' plot(out2$Y, main="ENET::(1,  0.1)")
#' plot(out3$Y, main="ENET::(10, 0.1)")
#' plot(out4$Y, main="ENET::(0.1,1)")
#' plot(out5$Y, main="ENET::(1,  1)")
#' plot(out6$Y, main="ENET::(10, 1)")
#' plot(out7$Y, main="ENET::(0.1,10)")
#' plot(out8$Y, main="ENET::(1,  10)")
#' plot(out9$Y, main="ENET::(10, 10)")
#' par(opar)
#' }
#'
#' @references
#' \insertRef{zou_regularization_2005}{ADMM}
#'
#' @rdname linear_ENET
#' @author Kisung You
#' @export
do.enet <- function(X, response, ndim=2, preprocess=c("null","center","scale","cscale","decorrelate","whiten"),
                    ycenter=FALSE, lambda1=1.0, lambda2=1.0){
  #------------------------------------------------------------------------
  ## PREPROCESSING
  #   1. data matrix
  aux.typecheck(X)
  n = nrow(X)
  p = ncol(X)
  #   2. response
  response = as.double(response)
  if ((any(is.infinite(response)))||(!is.vector(response))||(any(is.na(response)))){
    stop("* do.enet : 'response' should be a vector containing no NA values.")
  }
  #   3. ndim
  ndim = as.integer(ndim)
  if (!check_ndim(ndim,p)){stop("* do.enet : 'ndim' is a positive integer in [1,#(covariates)).")}
  #   4. preprocess
  if (missing(preprocess)){
    algpreprocess = "null"
  } else {
    algpreprocess = match.arg(preprocess)
  }
  #   5. lambda
  lambdaval1 = as.double(lambda1)
  lambdaval2 = as.double(lambda2)
  if (!check_NumMM(lambdaval1,0,1e+10,compact=FALSE)){stop("* do.enet : 'lambda1' should be a nonnegative real number.")}
  if (!check_NumMM(lambdaval1,0,1e+10,compact=FALSE)){stop("* do.enet : 'lambda1' should be a nonnegative real number.")}

  #------------------------------------------------------------------------
  ## COMPUTATION : DATA PREPROCESSING
  tmplist = aux.preprocess.hidden(X,type=algpreprocess,algtype="linear")
  trfinfo = tmplist$info
  pX      = tmplist$pX

  if (!is.logical(ycenter)){
    stop("* do.enet : 'ycenter' should be a logical variable.")
  }
  if (ycenter==TRUE){
    response = response-mean(response)
  }

  #------------------------------------------------------------------------
  ## COMPUTATION : MAIN COMPUTATION FOR Elastic Net
  #   1. run ENET
  runENET   = ADMM::admm.enet(pX, response, lambda1=lambdaval1, lambda2=lambdaval2)
  #   2. take the score
  lscore     = abs(as.vector(runENET$x))
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
