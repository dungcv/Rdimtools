#' Supervised Locality Pursuit Embedding
#'
#' Supervised Locality Pursuit Embedding (SLPE) is a supervised extension of LPE
#' that uses class labels of data points in order to enhance discriminating power in
#' its mapping into a low dimensional space.
#'
#' @param X an \eqn{(n\times p)} matrix or data frame whose rows are observations
#' and columns represent independent variables.
#' @param label a length-\eqn{n} vector of data class labels.
#' @param ndim an integer-valued target dimension.
#' @param preprocess  an additional option for preprocessing the data.
#' Default is "center" and other options of "decorrelate" and "whiten"
#' are supported. See also \code{\link{aux.preprocess}} for more details.
#'
#' @return a named list containing
#' \describe{
#' \item{Y}{an \eqn{(n\times ndim)} matrix whose rows are embedded observations.}
#' \item{trfinfo}{a list containing information for out-of-sample prediction.}
#' \item{projection}{a \eqn{(p\times ndim)} whose columns are basis for projection.}
#' }
#'
#' @examples
#' \dontrun{
#' ## generate data of 2 types with clear difference
#' diff = 15
#' dt1  = aux.gensamples(n=123)-diff;
#' dt2  = aux.gensamples(n=123)+diff;
#'
#' ## merge the data and create a label correspondingly
#' X      = rbind(dt1,dt2)
#' label  = c(rep(1,123), rep(2,123))
#'
#' ## compare SLPE with SLPP
#' out1 <- do.slpp(X, label)
#' out2 <- do.slpe(X, label)
#'
#' ## visualize
#' par(mfrow=c(1,2))
#' plot(out1$Y[,1], out1$Y[,2], main="SLPP")
#' plot(out2$Y[,1], out2$Y[,2], main="SLPE")
#' }
#'
#' @references
#' \insertRef{zheng_supervised_2006}{Rdimtools}
#'
#' @author Kisung You
#' @seealso \code{\link{do.lpe}}
#' @rdname linear_SLPE
#' @export
do.slpe <- function(X, label, ndim=2, preprocess=c("center","decorrelate","whiten")){
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
  if (any(is.na(label))||(any(is.infinite(label)))){
    stop("* Supervised Learning : any element of 'label' as NA or Inf will simply be considered as a class, not missing entries.")
  }
  labelorder = order(label)
  labelrank  = rank(label)
  newlabel   = label[labelorder]
  #   3. ndim
  ndim = as.integer(ndim)
  if (!check_ndim(ndim,p)){stop("* do.slpe : 'ndim' is a positive integer in [1,#(covariates)).")}
  #   4. preprocess
  if (missing(preprocess)){    algpreprocess = "center"  }
  else {    algpreprocess = match.arg(preprocess)  }


  #------------------------------------------------------------------------
  ## COMPUTATION : PRELIMINARY
  #   1. preprocessing
  tmplist = aux.preprocess(X,type=algpreprocess)
  trfinfo = tmplist$info
  pX      = tmplist$pX
  trfinfo$algtype = "linear"
  #   2. re-arranging using labelorder
  opX = pX[labelorder,]
  #   3. PCA preprocessing
  eigtest = eigen(cov(opX), only.values=TRUE)
  pcadim  = sum(eigtest$values > 0)
  if (pcadim <= ndim){
    warning("* do.slpe : target 'ndim' is larger than intrinsic data dimension achieved from PCA.")
    projection_first = diag(p)
    pcapX = opX%*%projection_first
  } else{
    projection_first = aux.adjprojection(eigen(cov(pX))$vectors[,1:pcadim])
    pcapX = opX%*%projection_first
  }

  #------------------------------------------------------------------------
  ## COMPUTATION : MAIN PART FOR SLPE
  #   1. build such a weird similarity measure matrix S
  S = array(0,c(n,n))
  unewlabel = unique(newlabel)
  for (i in 1:length(ulabel)){
    #   1-1. find current label
    idxcurrent = which(newlabel==unewlabel[i])
    #   1-2. build submatrix Bi
    ncurrent = length(idxcurrent)
    Bi = array(1,c(ncurrent,ncurrent)); diag(Bi) = 0;
    #   1-3. fill in
    S[idxcurrent,idxcurrent] = Bi
  }
  #   2. build diagonal & laplacian matrix
  D = diag(rowSums(S))
  L = D-S
  #   3. geigen : lowest
  LHS = t(pcapX)%*%L%*%pcapX
  RHS = t(pcapX)%*%D%*%pcapX
  projection_second = aux.adjprojection(geigen::geigen(LHS,RHS)$vectors[,1:ndim])


  #------------------------------------------------------------------------
  ## RETURN
  #   1. throughput projection
  projection = aux.adjprojection(projection_first%*%projection_second)

  #   2. report : oh, don't forget to re-ordering the data according to 'rank'
  result = list()
  result$Y = (pcapX%*%projection_second)[labelrank,]
  result$trfinfo = trfinfo
  result$projection = projection
  return(result)
}













