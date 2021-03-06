% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/linear_ASI.R
\name{do.asi}
\alias{do.asi}
\title{Adaptive Subspace Iteration}
\usage{
do.asi(
  X,
  ndim = 2,
  preprocess = c("center", "scale", "cscale", "decorrelate", "whiten"),
  maxiter = 10,
  abstol = 0.001
)
}
\arguments{
\item{X}{an \eqn{(n\times p)} matrix or data frame whose rows are observations.}

\item{ndim}{an integer-valued target dimension.}

\item{preprocess}{an additional option for preprocessing the data.
Default is "center". See also \code{\link{aux.preprocess}} for more details.}

\item{maxiter}{maximum number of iterations allowed.}

\item{abstol}{stopping criterion for incremental change in projection matrix.}
}
\value{
a named list containing
\describe{
\item{Y}{an \eqn{(n\times ndim)} matrix whose rows are embedded observations.}
\item{trfinfo}{a list containing information for out-of-sample prediction.}
\item{projection}{a \eqn{(p\times ndim)} whose columns are basis for projection.}
}
}
\description{
Adaptive Subspace Iteration (ASI) iteratively finds the best subspace to perform data clustering. It can be regarded as
one of remedies for clustering in high dimensional space. Eigenvectors of a within-cluster scatter matrix are used
as basis of projection.
}
\examples{
## generate swiss-roll data
X = aux.gensamples(n=200)

## try different tolerance level
out1 = do.asi(X, abstol=1e-2)
out2 = do.asi(X, abstol=1e-3)
out3 = do.asi(X, abstol=1e-4)

## visualize
opar <- par(no.readonly=TRUE)
par(mfrow=c(1,3))
plot(out1$Y, main="ASI::tol=1e-2", pch=19, cex=0.5)
plot(out2$Y, main="ASI::tol=1e-3", pch=19, cex=0.5)
plot(out3$Y, main="ASI::tol=1e-4", pch=19, cex=0.5)
par(opar)

}
\references{
\insertRef{li_document_2004}{Rdimtools}
}
\seealso{
\code{\link{do.ldakm}}
}
\author{
Kisung You
}
