% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/server_metadata.R
\name{terms_of_service}
\alias{terms_of_service}
\title{Visualize the terms of service}
\usage{
terms_of_service(con = NULL)
}
\arguments{
\item{con}{a connected openEO client object (optional) otherwise \code{\link[=active_connection]{active_connection()}}
is used.}
}
\value{
a list of the link identifying the terms of service from the service capabilities or NULL
}
\description{
If the service provides information about their terms of service in the capabilities, the function opens a new RStudio
viewer panel and visualizes the HTML content of the link.
}
