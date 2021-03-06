#' Locality Preserving Projection
#'
#' \code{do.lpp} is a linear approximation to Laplacian Eigenmaps. More precisely,
#' it aims at finding a linear approximation to the eigenfunctions of the Laplace-Beltrami
#' operator on the graph-approximated data manifold.
#'
#' @param X an \eqn{(n\times p)} matrix or data frame whose rows are observations
#' @param ndim an integer-valued target dimension.
#' @param type a vector of neighborhood graph construction. Following types are supported;
#'  \code{c("knn",k)}, \code{c("enn",radius)}, and \code{c("proportion",ratio)}.
#'  Default is \code{c("proportion",0.1)}, connecting about 1/10 of nearest data points
#'  among all data points. See also \code{\link{aux.graphnbd}} for more details.
#' @param symmetric one of \code{"intersect"}, \code{"union"} or \code{"asymmetric"} is supported. Default is \code{"union"}.
#' See also \code{\link{aux.graphnbd}} for more details.
#' @param preprocess  an additional option for preprocessing the data.
#' Default is \code{"center"}. See also \code{\link{aux.preprocess}} for more details.
#' @param t bandwidth for heat kernel in \eqn{(0,\infty)}.
#'
#' @return a named list containing
#' \describe{
#' \item{Y}{an \eqn{(n\times ndim)} matrix whose rows are embedded observations.}
#' \item{projection}{a \eqn{(p\times ndim)} whose columns are basis for projection.}
#' \item{trfinfo}{a list containing information for out-of-sample prediction.}
#' }
#'
#' @examples
#' ## generate twinpeaks data
#' X <- aux.gensamples(dname="twinpeaks",n=100)
#'
#' ## try different kernel bandwidths
#' out1 <- do.lpp(X, t=0.1)
#' out2 <- do.lpp(X, t=1)
#' out3 <- do.lpp(X, t=10)
#'
#' ## Visualize three different projections
#' opar <- par(no.readonly=TRUE)
#' par(mfrow=c(1,3))
#' plot(out1$Y, main="LPP::bandwidth=0.1")
#' plot(out2$Y, main="LPP::bandwidth=1")
#' plot(out3$Y, main="LPP::bandwidth=10")
#' par(opar)
#'
#' @references
#' \insertRef{he_locality_2005}{Rdimtools}
#'
#' @author Kisung You
#' @rdname linear_LPP
#' @export
do.lpp <- function(X, ndim=2, type=c("proportion",0.1),
                   symmetric=c("union","intersect","asymmetric"),
                   preprocess=c("center","scale","cscale","whiten","decorrelate"), t=1.0){
  #------------------------------------------------------------------------
  ## PREPROCESSING
  # 1. typecheck is always first step to perform.
  aux.typecheck(X)
  if ((!is.numeric(ndim))||(ndim<1)||(ndim>ncol(X))||is.infinite(ndim)||is.na(ndim)){
    stop("* do.lpp : 'ndim' is a positive integer in [1,#(covariates)].")
  }
  ndim = as.integer(ndim)

  # 2. ... parameters
  # 2-1. aux.graphnbd
  #   type : vector of c("knn",k), c("enn",radius), or c("proportion",ratio)
  #   symmetric : 'intersect','union', or 'asymmetric'
  # 2-2. LPP itself
  #   weight     : TRUE
  #   preprocess : 'null','center','decorrelate', or 'whiten'
  #   t          : heat kernel bandwidth

  nbdtype = type;
  if (missing(symmetric)){
    nbdsymmetric = "union"
  } else {
    nbdsymmetric = match.arg(symmetric)
  }
  if (missing(preprocess)){
    algpreprocess = "center"
  } else {
    algpreprocess = match.arg(preprocess)
  }
  t = as.double(t)
  if (!check_NumMM(t,.Machine$double.eps,Inf)){stop("* do.lpp : 't' is a bandwidth parameter in (0,infinity).")}

  # 3. process : data preprocessing
  tmplist = aux.preprocess.hidden(X,type=algpreprocess,algtype="linear")
  trfinfo = tmplist$info
  pX      = tmplist$pX

  # 4. process : neighborhood selection
  nbdstruct = aux.graphnbd(pX,method="euclidean",
                           type=nbdtype,symmetric=nbdsymmetric)


  #------------------------------------------------------------------------
  ## COMPUTATION : MAIN FOR LPP
  #   1. choose the weights
  tmpW    = exp(-(as.matrix(dist(pX))^2)/t)
  nbdmask = nbdstruct$mask
  if (is.infinite(t)){
    matW = nbdmask*1.0
  } else {
    matW = tmpW*nbdmask
  }

  #   2. compute auxiliary matrices for eigenmaps
  matD = diag(rowSums(matW))
  matL = (matD-matW)

  #   3. two terms and geigen
  LHS = t(pX)%*%matL%*%pX
  RHS = t(pX)%*%matD%*%pX
  projection = aux.geigen(LHS, RHS, ndim, maximal=FALSE)

  #------------------------------------------------------------------------
  ## RETURN
  result = list()
  result$Y = pX%*%projection
  result$trfinfo = trfinfo
  result$projection = projection
  return(result)
}
