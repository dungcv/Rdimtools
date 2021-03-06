% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/linear_ODP.R
\name{do.odp}
\alias{do.odp}
\title{Orthogonal Discriminant Projection}
\usage{
do.odp(
  X,
  label,
  ndim = 2,
  preprocess = c("center", "scale", "cscale", "decorrelate", "whiten"),
  type = c("proportion", 0.1),
  symmetric = c("union", "intersect", "asymmetric"),
  alpha = 0.5,
  beta = 10
)
}
\arguments{
\item{X}{an \eqn{(n\times p)} matrix or data frame whose rows are observations
and columns represent independent variables.}

\item{label}{a length-\eqn{n} vector of data class labels.}

\item{ndim}{an integer-valued target dimension.}

\item{preprocess}{an additional option for preprocessing the data.
Default is "center". See also \code{\link{aux.preprocess}} for more details.}

\item{type}{a vector of neighborhood graph construction. Following types are supported;
\code{c("knn",k)}, \code{c("enn",radius)}, and \code{c("proportion",ratio)}.
Default is \code{c("proportion",0.1)}, connecting about 1/10 of nearest data points
among all data points. See also \code{\link{aux.graphnbd}} for more details.}

\item{symmetric}{one of \code{"intersect"}, \code{"union"} or \code{"asymmetric"} is supported. Default is \code{"union"}. See also \code{\link{aux.graphnbd}} for more details.}

\item{alpha}{balancing parameter of non-local and local scatter in \eqn{[0,1]}.}

\item{beta}{scaling control parameter for distant pairs of data in \eqn{(0,\infty)}.}
}
\value{
a named list containing
\describe{
\item{Y}{an \eqn{(n\times ndim)} matrix whose rows are embedded observations.}
\item{projection}{a \eqn{(p\times ndim)} whose columns are basis for projection.}
\item{trfinfo}{a list containing information for out-of-sample prediction.}
}
}
\description{
Orthogonal Discriminant Projection (ODP) is a linear dimension reduction method with label information, i.e., \emph{supervised}.
The method maximizes weighted difference between local and non-local scatter while local information is also preserved by
constructing a neighborhood graph.
}
\examples{
## use iris data
data(iris)
X     = as.matrix(iris[,1:4])
label = as.integer(iris$Species)

## try different beta (scaling control) parameter
out1 = do.odp(X, label, beta=1)
out2 = do.odp(X, label, beta=10)
out3 = do.odp(X, label, beta=100)

## visualize
opar <- par(no.readonly=TRUE)
par(mfrow=c(1,3))
plot(out1$Y, col=label, main="ODP::beta=1")
plot(out2$Y, col=label, main="ODP::beta=10")
plot(out3$Y, col=label, main="ODP::beta=100")
par(opar)

}
\references{
\insertRef{li_supervised_2009}{Rdimtools}
}
