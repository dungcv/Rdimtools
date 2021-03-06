% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/linear_SDLPP.R
\name{do.sdlpp}
\alias{do.sdlpp}
\title{Sample-Dependent Locality Preserving Projection}
\usage{
do.sdlpp(
  X,
  ndim = 2,
  t = 1,
  preprocess = c("center", "scale", "cscale", "decorrelate", "whiten")
)
}
\arguments{
\item{X}{an \eqn{(n\times p)} matrix or data frame whose rows are observations.}

\item{ndim}{an integer-valued target dimension.}

\item{t}{kernel bandwidth in \eqn{(0,\infty)}.}

\item{preprocess}{an additional option for preprocessing the data.
Default is "center". See also \code{\link{aux.preprocess}} for more details.}
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
Many variants of Locality Preserving Projection are contingent on
graph construction schemes in that they sometimes return a range of
heterogeneous results when parameters are controlled to cover a wide range of values.
This algorithm takes an approach called \emph{sample-dependent construction} of
graph connectivity in that it tries to discover intrinsic structures of data
solely based on data.
}
\examples{
\donttest{
## use iris data
data(iris)
X     = as.matrix(iris[,1:4])
label = as.integer(iris$Species)

## compare with PCA
out1 <- do.pca(X,ndim=2)
out2 <- do.sdlpp(X, t=0.1)
out3 <- do.sdlpp(X, t=1)
out4 <- do.sdlpp(X, t=10)

## visualize
opar <- par(no.readonly=TRUE)
par(mfrow=c(2,2))
plot(out1$Y, col=label, main="PCA")
plot(out2$Y, col=label, main="SDLPP::t=0.1")
plot(out3$Y, col=label, main="SDLPP::t=1")
plot(out4$Y, col=label, main="SDLPP::t=10")
par(opar)
}


}
\references{
\insertRef{yang_sampledependent_2010}{Rdimtools}
}
\seealso{
\code{\link{do.lpp}}
}
\author{
Kisung You
}
