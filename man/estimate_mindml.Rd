% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/estimate_mindml.R
\name{est.mindml}
\alias{est.mindml}
\title{MINDml}
\usage{
est.mindml(X, k = 5)
}
\arguments{
\item{X}{an \eqn{(n\times p)} matrix or data frame whose rows are observations.}

\item{k}{the neighborhood size for defining locality.}
}
\value{
a named list containing containing \describe{
\item{estdim}{the global estimated dimension.}
}
}
\description{
It is a minimum neighbor distance estimator of the intrinsic dimension based on Maximum Likelihood principle.
}
\examples{
\donttest{
## create 3 datasets of intrinsic dimension 2.
X1 = aux.gensamples(dname="swiss")
X2 = aux.gensamples(dname="ribbon")
X3 = aux.gensamples(dname="saddle")

## acquire an estimate for intrinsic dimension
out1 = est.mindml(X1, k=10)
out2 = est.mindml(X2, k=10)
out3 = est.mindml(X3, k=10)

## print the results
sprintf("* est.mindml : estimated dimension for 'swiss'  data is \%.2f.",out1$estdim)
sprintf("* est.mindml : estimated dimension for 'ribbon' data is \%.2f.",out2$estdim)
sprintf("* est.mindml : estimated dimension for 'saddle' data is \%.2f.",out3$estdim)
}

}
\references{
\insertRef{lombardi_minimum_2011}{Rdimtools}
}
\seealso{
\code{\link{est.mindkl}}
}
\author{
Kisung You
}
