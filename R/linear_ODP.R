#' Orthogonal Discriminant Projection
#'
#' Orthogonal Discriminant Projection (ODP) is a linear dimension reduction method with label information, i.e., \emph{supervised}.
#' The method maximizes weighted difference between local and non-local scatter while local information is also preserved by
#' constructing a neighborhood graph.
#'
#' @param X an \eqn{(n\times p)} matrix or data frame whose rows are observations
#' and columns represent independent variables.
#' @param label a length-\eqn{n} vector of data class labels.
#' @param ndim an integer-valued target dimension.
#' @param preprocess an additional option for preprocessing the data.
#' Default is "center". See also \code{\link{aux.preprocess}} for more details.
#' @param type a vector of neighborhood graph construction. Following types are supported;
#'  \code{c("knn",k)}, \code{c("enn",radius)}, and \code{c("proportion",ratio)}.
#'  Default is \code{c("proportion",0.1)}, connecting about 1/10 of nearest data points
#'  among all data points. See also \code{\link{aux.graphnbd}} for more details.
#' @param symmetric one of \code{"intersect"}, \code{"union"} or \code{"asymmetric"} is supported. Default is \code{"union"}. See also \code{\link{aux.graphnbd}} for more details.
#' @param alpha balancing parameter of non-local and local scatter in \eqn{[0,1]}.
#' @param beta scaling control parameter for distant pairs of data in \eqn{(0,\infty)}.
#'
#' @return a named list containing
#' \describe{
#' \item{Y}{an \eqn{(n\times ndim)} matrix whose rows are embedded observations.}
#' \item{projection}{a \eqn{(p\times ndim)} whose columns are basis for projection.}
#' \item{trfinfo}{a list containing information for out-of-sample prediction.}
#' }
#'
#' @examples
#' ## use iris data
#' data(iris)
#' X     = as.matrix(iris[,1:4])
#' label = as.integer(iris$Species)
#'
#' ## try different beta (scaling control) parameter
#' out1 = do.odp(X, label, beta=1)
#' out2 = do.odp(X, label, beta=10)
#' out3 = do.odp(X, label, beta=100)
#'
#' ## visualize
#' opar <- par(no.readonly=TRUE)
#' par(mfrow=c(1,3))
#' plot(out1$Y, col=label, main="ODP::beta=1")
#' plot(out2$Y, col=label, main="ODP::beta=10")
#' plot(out3$Y, col=label, main="ODP::beta=100")
#' par(opar)
#'
#' @references
#' \insertRef{li_supervised_2009}{Rdimtools}
#'
#' @rdname linear_ODP
#' @export
do.odp <- function(X, label, ndim=2, preprocess=c("center","scale","cscale","decorrelate","whiten"),
                   type=c("proportion",0.1), symmetric=c("union","intersect","asymmetric"),
                   alpha = 0.5, beta = 10){
  ## Note : refer to do.klfda
  #------------------------------------------------------------------------
  ## PREPROCESSING
  #   1. data matrix
  aux.typecheck(X)
  n = nrow(X)
  p = ncol(X)
  #   2. label : check and return a de-factored vector
  #   For this example, there should be no degenerate class of size 1.
  label  = check_label(label, n)
  ulabel = unique(label)
  for (i in 1:length(ulabel)){
    if (sum(label==ulabel[i])==1){
      stop("* do.odp : no degerate class of size 1 is allowed.")
    }
  }
  if (any(is.na(label))||(any(is.infinite(label)))){
    stop("* Supervised Learning : any element of 'label' as NA or Inf will simply be considered as a class, not missing entries.")
  }
  #   3. ndim
  ndim = as.integer(ndim)
  if (!check_ndim(ndim,p)){stop("* do.odp : 'ndim' is a positive integer in [1,#(covariates)).")}
  #   4. preprocess
  if (missing(preprocess)){
    algpreprocess = "center"
  } else {
    algpreprocess = match.arg(preprocess)
  }
  #   5. nbd-type
  nbdtype = type
  #   6. nbd-symmetric
  if (missing(symmetric)){
    nbdsymmetric = "union"
  } else {
    nbdsymmetric = match.arg(symmetric)
  }
  #   7. alpha and beta
  alpha = as.double(alpha)
  if (!check_NumMM(alpha,0,1,compact=TRUE)){stop("* do.odp : 'alpha' is a balancing parameter in [0,1].")}
  beta = as.double(beta)
  if (!check_NumMM(beta,0,Inf,compact=FALSE)){stop("* do.odp : 'beta' is a scaling control parameter in (0,inf).")}
  #------------------------------------------------------------------------
  ## COMPUTATION : PRELIMINARY
  #   1. Preprocessing the data
  tmplist = aux.preprocess.hidden(X,type=algpreprocess,algtype="linear")
  trfinfo = tmplist$info
  pX      = tmplist$pX

  #   2. neighborhood information
  nbdstruct = aux.graphnbd(pX,method="euclidean",
                           type=nbdtype,symmetric=nbdsymmetric)
  nbdmask   = nbdstruct$mask
  #   3. Distance Matrix Squared
  Dmat2 = (as.matrix(dist(pX))^2)
  #   4. Construct W : weight matrix
  W = array(0,c(n,n))
  for (i in 1:(n-1)){
    for (j in (i+1):n){
      if ((nbdmask[i,j]==TRUE)&&(nbdmask[j,i]==TRUE)){ # neighbors of each other
        if (label[i]==label[j]){
          expval = exp((-Dmat2[i,j])/beta)
          W[i,j] = expval
          W[j,i] = expval
        } else {
          expval = exp((-Dmat2[i,j])/beta) ### this part should be changed with Modified ODP
          comval = expval*(1-expval)
          W[i,j] = comval
          W[j,i] = comval
        }
      }
    }
  }
  #   5. Construct Sl and St
  #   5-1. Sl : local
  L  = diag(rowSums(W))-W
  Sl = (t(pX)%*%L%*%pX)/(2*n*n)
  #   5-2. St : total : non-local Sn = St-Sl
  St = aux_scatter_pairwise(pX)/(2*n*n)

  #------------------------------------------------------------------------
  ## COMPUTATION : MAIN ODP
  #   1. cost function
  costS = ((1-alpha)*St)-(alpha*Sl)
  #   2. top eigenvectors
  projection = aux.adjprojection(RSpectra::eigs(costS, ndim)$vectors)

  #------------------------------------------------------------------------
  ## RETURN
  result = list()
  result$Y = pX%*%projection
  result$trfinfo = trfinfo
  result$projection = projection
  return(result)
}





