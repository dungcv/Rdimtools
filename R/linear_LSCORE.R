#' Laplacian Score
#'
#' Laplacian Score (LSCORE) is an unsupervised linear feature extraction method. For each
#' feature/variable, it computes Laplacian score based on an observation that data from the
#' same class are often close to each other. Its power of locality preserving property is used, and
#' the algorithm selects variables with largest scores.
#'
#' @examples
#' \dontrun{
#' ## generate data of 3 types with clear difference
#' dt1  = aux.gensamples(n=33)-100
#' dt2  = aux.gensamples(n=33)
#' dt3  = aux.gensamples(n=33)+100
#'
#' ## merge the data and create a label correspondingly
#' X      = rbind(dt1,dt2,dt3)
#' label  = c(rep(1,33), rep(2,33), rep(3,33))
#'
#' ## try different kernel bandwidth
#' out1 = do.lscore(X, t=0.1)
#' out2 = do.lscore(X, t=1)
#' out3 = do.lscore(X, t=10)
#'
#' ## visualize
#' par(mfrow=c(1,3))
#' plot(out1$Y[,1], out1$Y[,2], main="bandwidth=0.1")
#' plot(out2$Y[,1], out2$Y[,2], main="bandwidth=1")
#' plot(out3$Y[,1], out3$Y[,2], main="bandwidth=10")
#' }
#'
#' @param X an \eqn{(n\times p)} matrix or data frame whose rows are observations
#' and columns represent independent variables.
#' @param ndim an integer-valued target dimension.
#' @param type a vector of neighborhood graph construction. Following types are supported;
#'  \code{c("knn",k)}, \code{c("enn",radius)}, and \code{c("proportion",ratio)}.
#'  Default is \code{c("proportion",0.1)}, connecting about 1/10 of nearest data points
#'  among all data points. See also \code{\link{aux.graphnbd}} for more details.
#' @param preprocess an additional option for preprocessing the data.
#' Default is "null" and other options of "center", "decorrelate" and "whiten"
#' are supported. See also \code{\link{aux.preprocess}} for more details.
#' @param t bandwidth parameter for heat kernel in \eqn{(0,\infty)}.
#'
#' @return a named list containing
#' \describe{
#' \item{Y}{an \eqn{(n\times ndim)} matrix whose rows are embedded observations.}
#' \item{featidx}{a length-\eqn{ndim} vector of indices with highest scores.}
#' \item{trfinfo}{a list containing information for out-of-sample prediction.}
#' \item{projection}{a \eqn{(p\times ndim)} whose columns are basis for projection.}
#' }
#'
#' @references
#' \insertRef{he_laplacian_2005}{Rdimtools}
#'
#' @rdname linear_LSCORE
#' @author Kisung You
#' @export
do.lscore <- function(X, ndim=2, type=c("proportion",0.1),
                      preprocess=c("null","center","whiten","decorrelate"), t=10.0){
  #------------------------------------------------------------------------
  ## PREPROCESSING
  #   1. data matrix
  aux.typecheck(X)
  n = nrow(X)
  p = ncol(X)
  #   2. ndim
  ndim = as.integer(ndim)
  if (!check_ndim(ndim,p)){
    stop("* do.lscore : 'ndim' is a positive integer in [1,#(covariates)].")
  }
  #   3. type
  nbdtype = type
  nbdsymmetric = "union"
  #   4. preprocess
  if (missing(preprocess)){
    algpreprocess = "null"
  } else {
    algpreprocess = match.arg(preprocess)
  }
  #   5. t : kernel bandwidth
  t = as.double(t)
  if (!check_NumMM(t, 1e-15, Inf, compact=TRUE)){stop("* do.lscore : 't' is a kernel bandwidth parameter in (0,Inf).")}

  #------------------------------------------------------------------------
  ## COMPUTATION : PRELIMINARY
  #   1. preprocessing of data : note that output pX still has (n-by-p) format
  if (algpreprocess=="null"){
    trfinfo = list()
    trfinfo$type = "null"
    pX = X
  } else {
    tmplist = aux.preprocess(X,type=algpreprocess)
    trfinfo = tmplist$info
    pX      = tmplist$pX
  }
  trfinfo$algtype = "linear"

  #   2. build neighborhood information
  nbdstruct = aux.graphnbd(pX,method="euclidean",
                           type=nbdtype,symmetric=nbdsymmetric)
  nbdmask   = nbdstruct$mask

  #------------------------------------------------------------------------
  ## COMPUTATION : MAIN PART FOR LAPLACIAN SCORE
  #   1. weight matrix
  Dsqmat  = exp(-(as.matrix(dist(pX))^2)/t)
  S       = Dsqmat*nbdmask
  diag(S) = 0
  #   2. auxiliary matrices
  D = diag(rowSums(S))
  L = D-S
  #   3. compute Laplacian score
  n1 = as.vector(rep(1,n))
  D1 = as.vector(D%*%matrix(rep(1,n)))
  fscore = rep(0,p)
  for (j in 1:p){
    # 3-1. select each feature
    fr = as.vector(pX[,j])
    # 3-2. adjust fr
    corrector  = as.double(sum(fr*D1)/sum(n1*D1))
    frtilde    = fr-corrector
    matfrtilde = matrix(frtilde)
    # 3-3. compute the score
    term1 = sum(as.vector(L%*%matfrtilde)*frtilde)
    term2 = sum(as.vector(D%*%matfrtilde)*frtilde)
    fscore[j] = term1/term2
  }
  #   4. select the largest ones
  idxvec = base::order(fscore, decreasing=TRUE)[1:ndim]
  #   5. find the projection matrix
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