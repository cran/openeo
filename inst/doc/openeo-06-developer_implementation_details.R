## ---- eval=FALSE--------------------------------------------------------------
#  ProcessCollection = R6Class(
#      "ProcessCollection",
#      lock_objects = FALSE,
#      ...)

## ---- eval=FALSE--------------------------------------------------------------
#  URI = R6Class(
#    "uri",
#    inherit=Argument,
#    public = list(
#      initialize=function(name=character(),description=character(),required=FALSE) {
#        private$name = name
#        private$description = description
#        private$required = required
#        private$schema$type = "string"
#        private$schema$subtype = "uri"
#      }
#    ), ...)

