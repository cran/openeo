#'@include utilities.R
#'@include authentication.R
NULL

#' openEO client class
#'
#' An R6Class that interacts with an openEO compliant back-end.
#' 
#' @name OpenEOClient
#' 
#' @field user_id The user_id obtained after authentication
#' @field api.mapping The mapping of the API endpoints and the back-end published ones
#' 
#' @section Methods:
#' \describe{
#'   \item{`$new(host=NULL)`}{the constructor with an optional host URL to connect to}
#'   \item{`$getBackendEndpoint(endpoint_name)`}{returns the URL for the requested endpoint tag}
#'   \item{`$request(tag,parameters=NULL,authorized=FALSE, ...)`}{performs the desired HTTP request by endpoint tag with 
#'   path parameters and whether or not authorization (access_token) is necessary}
#'   \item{`$isConnected()`}{whether or not the client has a host set}
#'   \item{`$isLoggedIn()`}{returns a logical describing whether the user is logged in}
#'   \item{`$getHost()`}{returns the host URL}
#'   \item{`$stopIfNotConnected()`}{throws an error if called and the client is not connected}
#'   \item{`$connect(url=NULL,version=NULL)`}{connects to a specific version of a back-end}
#'   \item{`$disconnect()`}{disconnects from the back-end by logout and clearing of active back-end package variables}
#'   \item{`$api_version()`}{returns the openEO API version this client is compliant to}
#'   \item{`$login(user=NULL, password=NULL,provider=NULL,config=NULL)`}{creates an [IAuth()] object}
#'   \item{`$logout()`}{invalidates the access_token and terminates the current session}
#'   \item{`$getAuthClient()`}{returns the authentication client}
#'   \item{`$setAuthClient(value)`}{sets the authentication client if it was configured and set externally}
#'   \item{`$getCapabilities()`}{service exploration to retrieve the supported openEO endpoints}
#'   \item{`$getId()`}{returns the ID of the Connection as stated in the getCapabilities document}
#'   \item{`$getTitle()`}{returns the title of the connection as stated in the getCapabilities document}
#' }
#' 
#' @section Arguments:
#' \describe{
#'   \item{`host`}{the openEO host URL}
#'   \item{`endpoint_name`}{the endpoint tag the client uses for the endpoints}
#'   \item{`tag`}{endpoint tag}
#'   \item{`parameters`}{named list of values to be replaced in the endpoint}
#'   \item{`authorized`}{whether or not the endpoint requires authentication via access_token}
#'   \item{`url`}{url of an openEO back-end either directly versioned or with the separate version statement}
#'   \item{`version`}{the openEO API version to be used, or a list of available API versions if set to NULL}
#'   \item{`user`}{the user name}
#'   \item{`password`}{the user password}
#'   \item{`value`}{an authentication object}
#' }
NULL

#' @importFrom R6 R6Class
#' @importFrom rlang is_null
#' @import httr2
#' @import jsonlite
#' @export
OpenEOClient <- R6Class(
  "OpenEOClient",
  # public ----
  public = list(
    # attributes ====
    user_id = NULL,
    
    api.mapping = NULL,

    # functions ====
    initialize = function(host=NULL) {
      if (!is.null(host)) {
        private$setHost(host = host)
      }
      
      active_connection(con=self)
    },
    getBackendEndpoint = function(endpoint_name) {
      if (!is.null(self$api.mapping)) {

        endpoint = self$api.mapping[self$api.mapping$tag == endpoint_name & self$api.mapping$available, "endpoint"]
        
        if (isNamespaceLoaded("tibble")) endpoint = endpoint[[1]]
        
        if (length(endpoint) > 0) {
          if (startsWith(endpoint,"/")) {
            return(substr(endpoint,2,nchar(endpoint)))
          } else {
            return(endpoint)
          }
        } else {
          stop("Endpoint for this function is not supported by the current back-end.")
        }
        
      } else {
        stop("Not connected / logged in. You need to connect or login to a back-end.")
      }
    },
    
    request = function(tag,parameters=NULL, authorized=FALSE, ...) {
      http_operation=toupper(self$api.mapping[as.vector(self$api.mapping[,"tag"] == tag),"operation"][[1]])
      
      endpoint_requires_path_params = requires_endpoint_parameter(self$getBackendEndpoint(tag))
      
      if (endpoint_requires_path_params && !is.na(parameters) && length(parameters) == 0) {
        stop(paste0("Endpoint '",self$getBackendEndpoint(tag),"' requires parameters, which are not set."))
      }
      
      if (length(parameters) >0 && !is.na(parameters) && endpoint_requires_path_params) {
        endpoint= do.call(replace_endpoint_parameter, append(list(self$getBackendEndpoint(tag)),as.list(parameters)))
      } else  {
        endpoint= self$getBackendEndpoint(tag)
      }
      
      
      return(do.call(private[[http_operation]], append(list(endpoint=endpoint,authorized=authorized),list(...))))
    },
    isConnected = function() {
      return(!is.null(private$host))
    },
    isLoggedIn = function() {
      tryCatch({
        if (is.null(private$auth_client) || length(private$auth_client$access_token) == 0) {
          return(FALSE)
        } 
        
        return(TRUE)
      }, error = function(e) {
        return(FALSE)
      })
    },
    getHost = function() {
      return(private$host)
    },
    stopIfNotConnected = function() {
      if (!self$isConnected()) {
        stop("Not connected to a back-end. Please connect to one before proceeding")
      }
    },
    disconnect = function() {
      observer = getOption("connectionObserver")
      
      if (is_logged_in()) logout()
      
      if (!is.null(observer)) observer$connectionClosed(type="OpenEO Service",host=private$host)
      .remove_connection(con = self)
      
      .initPackageEnvVariables()
      
    },
    connect = function(url=NULL,version=NULL,exchange_token="access_token") {
      
      tryCatch({
        if (is.null(url) && length(self$getHost()) == 0) {
          message("Note: Host-URL is missing")
          return(invisible(self))
        }
        
        if (!is.null(url)) {
          private$setHost(url)
        }
        response = NULL
        is_wellknown_endpoint = TRUE
        tryCatch({
          response = api_versions(url = self$getHost())
        }, error = function(e) {
          # just maybe we have a direct link, then skip all the version resolve
          is_wellknown_endpoint = FALSE
        })
        
        if (length(response) == 0) {
          is_wellknown_endpoint = FALSE
        }
        
        private$exchange_token = exchange_token
        
        if (!is_wellknown_endpoint) {
          #TODO build the hostInfo!
          # hostInfo -> data.frame with api_version, production, url
          # try to resolve url directly
          tryCatch({
            capabilities = self$getCapabilities()
            if (all(c("api_version","production") %in% names(capabilities))) {
              hostInfo = data.frame(api_version = capabilities[["api_version"]],
                                       production = capabilities[["production"]],
                                       url = paste0(private$host,"/"))
            } else {
              stop("URL is not a valid endpoint. Neither wellknown-endpoint nor capabilities can be derived.")
            }
          })
          
        } else {
          # Goal: resolve the back-ends .well-known/openeo endpoint and check if the default version or 
          # specified version is suitable
          if (!is.null(version)) {
            # url is not specific, then resolve /.well-known/openeo and check if the version is allowed
            hostInfo = private$backendVersions()$versions
            
            versionLabels = sapply(hostInfo,function(x)x$api_version)
            names(hostInfo) = versionLabels
            
            if (!version %in% versionLabels) {
              # print the available versions
              message(paste("Version",version,"is not provided by the back-end. Please choose one of the following",
                            paste(versionLabels,collapse=",")))
              return(invisible(self))
            } else {
              url = hostInfo[[version]]$url
              
              private$setHost(url)
            }
            
            hostInfo = as.data.frame(unname(hostInfo),stringsAsFactors = FALSE) # transform the list explicitly into a data.frame
          } else {
            
            if ("versions" %in% names(private$backendVersions())) {
              hostInfo=as.data.frame(private$backendVersions())
              
              
              for (i in 1:ncol(hostInfo)) {
                hostInfo[,i] = unlist(hostInfo[,i])
              }
              
              # select highest API version that is production ready. if none is production
              # ready, then select highest version
              hostInfo = .version_sort(hostInfo)
              private$setHost(hostInfo[1,"url"])
            }
          }
        }
        
        hostInfo$url = sapply(hostInfo$url, function(url) {
          #modify url (strip trailing slashes) to ensure a match for productivity check
          if (endsWith(url,"/")) {
            return(substr(url,1,nchar(url)-1))
          }
          
          return(url)
        })
        
        
        # set active connection
        active_connection(con = self)
        
        self$api.mapping = endpoint_mapping(self)
        cat("Connected to service: ",private$host,"\n")
        
        void = list_collections()
        
        # connections contract for RStudio
        .fill_rstudio_connection_observer()
        
        
        
        cat("Please check the terms of service (terms_of_service()) and the privacy policy (privacy_policy()). By further usage of this service, you acknowledge and agree to those terms and policies.\n")

        if (!hostInfo[hostInfo$url == private$host,]$production) {
          message("Warning: Connected host is not production-ready. Unexpected errors might occur.")
        }
        
        void = list_processes(self)
        
        return(invisible(self))
        
      }, 
      error = .capturedErrorToMessage
      )

    },
    api_version = function () {
      return(private$version)
    },
    login = function(login_type=NULL, user=NULL, password=NULL, provider=NULL, config=NULL) {
      if (length(login_type) > 0) {
        warning("parameter 'login_type' is deprecated and unused")
      }
      
      self$stopIfNotConnected()
      
      tryCatch({
        if (!is.null(user) && !is.null(password)) {
          private$loginBasic(user=user, password = password)
        }
        else {
          # select a default provider during login for OIDC
          private$loginOIDC(provider = provider, config = config)
        }
        
        invisible(self)
      },
      error=.capturedErrorToMessage)
      
      .refresh_rstudio_connection_observer()
    },
    logout = function() {
      if (!is.null(private$auth_client)){
        private$auth_client$logout()
      }
      
      
      
      assign(x = "active_connection", value = NULL, envir = pkgEnvironment)
      
      observer = getOption("connectionObserver")
      
      if (!is.null(observer)) observer$connectionClosed(type="OpenEO Service",host=private$host)
    },
    
    getAuthClient = function() {
      return(private$auth_client)
    },
    
    setAuthClient = function(value) {
      if (is.null(value)) {
        return(invisible(self))
      }
      
      if (!"IAuth" %in% class(value)) {
        stop("Value is no authentication class")
      }
      
      private$auth_client = value
      
      return(invisible(self))
    },
    
    getCapabilities = function() {
      if (is.null(private$capabilities)) {
        tryCatch({
          private$capabilities = private$GET(endpoint = "")
            
          class(private$capabilities) = "OpenEOCapabilities"
        }, error = .capturedErrorToMessage)
      }
      
      return(private$capabilities)
    },
    
    getId =function() {
      cap = self$getCapabilities()
      
      return(cap$id)
    },
    
    getTitle = function() {
      cap = self$getCapabilities()
      
      return(cap$title)
    }
    
    

  ),
  # private ----
  private = list(
    # attributes ====
    auth_client = NULL,
    user = NULL,
    password = NULL,
    host = NULL,
    version = "1.1.0", # implemented api version
    general_auth_type = "bearer",
    exchange_token="access_token",
    capabilities=NULL,
    
    # functions ====
    setHost = function(host) {
      if (endsWith(host,"/")) {
        host = substr(host,1,nchar(host)-1)
      }
      
      private$host = host
    },
    loginOIDC = function(provider = NULL, config = NULL) {
      suppressWarnings({
        tryCatch({
            # old implementation
            # probably fetch resolve the potential string into a provider here
            provider = .get_oidc_provider(provider)
            
            auth_code = "authorization_code"
            auth_pkce = "authorization_code+pkce"
            device_pkce = "urn:ietf:params:oauth:grant-type:device_code+pkce"
            device_code = "urn:ietf:params:oauth:grant-type:device_code"
            client_credentials = "client_credentials"
            
            has_default_clients = "default_clients" %in% names(provider) && length(provider[["default_clients"]]) > 0
            client_id_given = "client_id" %in% names(config)
            
            if (length(config) > 0)  {
              if (!is.list(config))  {
                stop("parameter 'config' is not a named list")
              }
              
              full_credentials = all(c("client_id","secret") %in% names(config))
              is_auth_code = length(config$grant_type) > 0 && config$grant_type == auth_code
              is_client_credentials = length(config$grant_type) > 0 && config$grant_type == client_credentials
              
              # either credentials are set and / or authorization_code or client_credentials as grant_type
              if (full_credentials && is_client_credentials) {
                private$auth_client = OIDCClientCredentialsFlow$new(provider = provider, config = config, force=TRUE)
              }
              else if (full_credentials && (is_auth_code || is.null(config$grant_type))) {
                private$auth_client = OIDCAuthCodeFlow$new(provider = provider, config = config, force=TRUE)
              }
              else if (is_auth_code || is_client_credentials) {
                stop("For grant type 'authorization_code' and 'client_credentials' a client_id and secret must be provided")
              }
              else if (client_id_given && has_default_clients) {
                default_clients = provider[["default_clients"]]
                # If a client_id is given, check whether we can use device code + pkce.
                # Otherwise, fall back to auth code + pkce (for backward compatibility)
                supported = which(sapply(default_clients, function(p) config$client_id == p$id))
                if (length(supported) > 0 && device_pkce %in% default_clients[[supported[[1]]]]$grant_types) {
                  config$grant_type = device_pkce
                } else if (length(supported) > 0 && device_code %in% default_clients[[supported[[1]]]]$grant_types) {
                  config$grant_type = device_code
                } else {
                  config$grant_type = auth_pkce
                }
              }
            }
            
            if (is.null(private$auth_client) && has_default_clients && !client_id_given) {
              default_clients = provider[["default_clients"]]

              # check whether user has chosen a grant type
              if ("grant_type" %in% names(config)) {
                config = .get_client(default_clients, config$grant_type, config)
              }
              else {
                # preferred device code + pkce
                config = .get_client(default_clients, device_pkce, config)
                # second choice auth_code + pkce
                
                if (is.null(config$client_id)) {
                  config = .get_client(default_clients, device_code, config)
                }
                
                if (is.null(config$client_id)) {
                  config = .get_client(default_clients, auth_pkce, config)
                }
              } 
              
              if (is.null(config$client_id)) {
                stop("Please provide a client id or a valid combination of client_id and grant_type.")
              }
            }
            
            if (is.null(private$auth_client)) {
              has_grant = "grant_type" %in% names(config)
              if (has_grant && device_pkce == config$grant_type) {
                private$auth_client = OIDCDeviceCodeFlowPkce$new(provider=provider, config = config)
              } else if (has_grant && device_code == config$grant_type) {
                private$auth_client = OIDCDeviceCodeFlow$new(provider=provider, config = config)
              } else if (has_grant && client_credentials == config$grant_type) {
                private$auth_client = OIDCClientCredentialsFlow$new(provider=provider, config = config)
              } else if (is.null(config$grant_type) || (has_grant && auth_pkce == config$grant_type)) {
                private$auth_client = OIDCAuthCodeFlowPKCE$new(provider=provider, config = config)
              }
            }

            if (is.null(private$auth_client)) {
              stop("The grant_type selected is not supported")
            }

            private$auth_client$login()
            cat("Login successful.\n")
            
            return(invisible(self))
        }, error=function(e){
          private$auth_client = NULL
          stop(paste0("Login failed. Reason: ",e$message))
        })
      })
    },
    
    loginBasic = function(user, password) {
      tryCatch({
        if (!is.null(self$api.mapping)) {
          tag = "login"
          endpoint = paste(self$getHost(),self$getBackendEndpoint(tag),sep="/")
        } else {
          endpoint = paste(self$getHost(),"credentials/basic",sep="/")
        }
        
        #endpoint,user,password
        private$auth_client = BasicAuth$new(endpoint,user,password)

        # user_id is probably user in BasicAuth, is this a relict from openeo 0.4?
        self$user_id = private$auth_client$login()
        cat("Login successful.\n")
        
        # in case there was no user_id provided in the authentication, set this user as user_id
        if (length(self$user_id)==0) self$user_id = user
        
        return(invisible(self))

      },
      error = .capturedErrorToMessage,
      finally = {
      })
    },
    backendVersions = function() {
      tryCatch({
        endpoint = ".well-known/openeo"
        
        info = private$GET(endpoint = endpoint,authorized = FALSE, type="application/json",auto_unbox=TRUE)
        class(info) = "VersionsList"
        
        return(info)
      },error= function(e) {
        # .capturedErrorToMessage(e) 
        return(list())
      })
      
    },

    GET = function(endpoint,authorized=FALSE,query = list(),parsed=TRUE, ...) {
      url = paste(private$host,endpoint, sep ="/")
      req = request(url)
      req = req_method(req, method="GET")
      
      args = list(...)
      
      if (authorized && !is.null(private$auth_client)) {
        
        header_list = private$addAuthorization()
        header_list[[".req"]] = req
        req = do.call(req_headers,header_list)
        
        # response = GET(url=url, config=private$addAuthorization(),query=query)
      } 
  
      # httr2 v0.2.0 changed parameter req to .req
      query[[".req"]] = req
      req = do.call(req_url_query,args = query)
      
      req = req_error(req,body=private$errorHandling)
      
      if (is.debugging()) {
        req_dry_run(req)
      }
      
      response = req_perform(req)
      
      if (is.debugging()) {
        print_response(response)
      }

      if (response$status_code < 400) {
        if (response$status_code != 202) {
          # info = content(response, ...)
          if (isTRUE(parsed)) {
            return(resp_body_json(response, ...))
          } else {
            return(response)
          }
          
        } else {
          return(NULL)
        }
        

      } else {
        private$errorHandling(response)
      }
    },
    DELETE = function(endpoint,authorized=FALSE,query = list(),...) {
      url = paste(private$host,endpoint,sep="/")
      
      req = request(url)
      req = req_method(req, method="DELETE")
      
      header = list(`.req` = req)
      if (authorized && !is.null(private$auth_client)) {
        header = private$addAuthorization(header)
        req = do.call(req_headers,header)
      }

      query[[".req"]] = req
      req = do.call(req_url_query,args = query)
      
      req = req_error(req,body=private$errorHandling)
      
      if (is.debugging()) {
        req_dry_run(req)
      }
      
      response = req_perform(req)
      
      # response = DELETE(url=url, config = header, ...)
      
      if (is.debugging()) {
        print_response(response)
      }
      
      # message = content(response)
      # message = resp_body_json(response)
      
      if (response$status_code < 400) {
        if (response$status_code == 204) {
          return(TRUE)
        }
      } else {
        private$errorHandling(response)
      }
      
      
    },
    POST = function(endpoint,authorized=FALSE,data=list(),encodeType = "json",query = list(), raw=FALSE,parsed=TRUE,...) {
      url = paste(private$host,endpoint,sep="/")
      req = request(url)
      req = req_method(req, method="POST")
      
      if (!is.list(query)) {
        stop("Query parameters are no list of key-value-pairs")
      }
      
      header = list(`.req` = req)
      if (authorized && !is.null(private$auth_client)) {
        header = private$addAuthorization(header)
      }
      
      req = do.call(req_headers,header)
      query[[".req"]] = req
      req = do.call(req_url_query,args = query)
      # response = req_perform(req)
      if (isTRUE(raw)) {
        if (file.exists(data)) {
          if (length(data) > 0) req = req_body_file(req,data, type = "application/octet-stream")
        } else {
          stop("Cannot find file for upload")
        }
        
      } else {
        if (length(data) > 0) req = req_body_json(req,data = data,auto_unbox = TRUE, ...)
      }
      
      req = req_error(req,body=private$errorHandling)
      
      if (is.debugging()) {
        req_dry_run(req)
      }
      
      response = req_perform(req)      

      if (is.debugging()) {
        print_response(response)
      }
      
      if (response$status_code < 400) {
        if (response$status_code != 202) {
          if (raw) {
            return(response)
          } else {
            # okMessage = content(response,"parsed","application/json")
            if (isFALSE(parsed)) {
              return(response)
            }
            okMessage = resp_body_json(response)
            
            return(okMessage)
          }
        } else {
          return(NULL)
        }
        
      } else {
        private$errorHandling(response)
      }
    },
    PUT = function(endpoint, authorized=FALSE, data=list(),encodeType = "json",query = list(), raw=FALSE,parsed=TRUE,...) {
      url = paste(private$host,endpoint,sep="/")
      
      req = request(url)
      req = req_method(req, method="PUT")
      
      header = list(`.req` = req)
      if (authorized && !is.null(private$auth_client)) {
        header = private$addAuthorization(header)
      }
      
      req = do.call(req_headers,header)
      query[[".req"]] = req
      req = do.call(req_url_query,args = query)
      if (isTRUE(raw)) {
        if (file.exists(data)) {
          if (length(data) > 0) req = req_body_file(req,data, type = "application/octet-stream")
        } else {
          stop("Cannot find file for upload")
        }
        
      } else {
        if (length(data) > 0) req = req_body_json(req,data = data,auto_unbox = TRUE, ...)
      }
      
      req = req_error(req,body=private$errorHandling)
      
      if (is.debugging()) {
        req_dry_run(req)
      }
      
      response = req_perform(req)  
      
      if (is.debugging()) {
        print_response(response)
      }
      
      if (response$status_code < 400) {
        if (response$status_code == 204) {
          return(TRUE)
        }
        
        # okMessage = content(response,"parsed","application/json")
        if (isFALSE(parsed)) {
          return(response)
        }
        okMessage = resp_body_json(response)
        return(okMessage)
      } else {
        private$errorHandling(response)
      }
    },
    PATCH = function(endpoint, authorized=FALSE, data=NULL, encodeType = NULL, parsed=TRUE, ...) {
      url = paste(private$host,endpoint,sep="/")
      req = request(url)
      req = req_method(req, method="PATCH")
      
      header = list(`.req` = req)
      if (authorized && !is.null(private$auth_client)) {
        header = private$addAuthorization(header)
        req = do.call(req_headers,header)
      }
      
      params = list(url=url, 
                    config = header)
      
      if (!is.null(data)) {
        req = req_body_json(req,data = data,auto_unbox = TRUE, ...)
      }
      
      req = req_error(req,body=private$errorHandling)
      
      if (is.debugging()) {
        req_dry_run(req)
      }
      
      response = req_perform(req)
      
      if (is.debugging()) {
        print_response(response)
      }
      
      if (response$status_code < 400) {
        if (response$status_code == 204) {
          return(TRUE)
        }
        
        # okMessage = content(response,"parsed","application/json")
        if (isFALSE(parsed)) {
          return(response)
        }
        okMessage = resp_body_json(response)
        return(okMessage)
      } else {
        private$errorHandling(response)
      }
    },

    # returns the header list and adds Authorization
    addAuthorization = function (header) {
      if (missing(header)) {
        header = list()
      }

      if (private$general_auth_type == "bearer") {
        if (!is.null(private$auth_client)) {
          header = append(header,list(
            Authorization=paste("Bearer",private$auth_client[[private$exchange_token]], sep =" ")
          ))
        } else {
          stop("Cannot add HTTP Authorization because you are not logged in.")
        }
        
      } else { # if all the endpoints require a basic encoded authorization header
        # header = append(header,authenticate(private$user,private$password,type = private$general_auth_type))
        header = append(header,list(
          Authorization=paste("Basic",private$auth_client[[private$exchange_token]], sep =" ")
        ))
      }

      return(header)
    },
    errorHandling = function(response) {
      if ("httr2_response" %in% class(response) || "response" %in% class(response) ) {
        # errorMessage = content(response)
        errorMessage = resp_body_json(response)
        if (!is.null(errorMessage[["message"]])) {
          paste("SERVER-ERROR:", errorMessage[["message"]])
        } else {
          # if there is an uncaptured error from the server then just return it as is
          paste("SERVER-ERROR:", errorMessage)
        }
      } else {
        # never happens? it is something else than response object
        response
      }
    }
  )

)

setOldClass(c("OpenEOClient","R6"))

#' @rdname status
#' @export
status.OpenEOClient = function(x, ...) {
  result = ""
  if (x$isConnected()) {
    result = "connected"
  }
  
  if (x$isLoggedIn()) {
    result = "authenticated"
  }
  
  return(result)
}

# client functions ----

#' Returns the client version
#' 
#' The function returns the client version. Wraps the call 'packageVersion("openeo")', which will return this packages version.
#' 
#' @return the client version
#' 
#' @importFrom utils packageVersion
#' @export
client_version = function() {
  return(packageVersion("openeo"))
}


.remove_connection = function(con) {
  genv_names = names(globalenv())
  sel = sapply(genv_names, function(var, con){
    obj = get(var)
    return(identical(obj, con))
  }, con = con)
  sel = which(sel)
  
  rm(list = names(sel), envir=globalenv())
}

.refresh_rstudio_connection_observer = function() {
  con = active_connection()
  
  if (is.null(con)) stop("openEO cannot refresh the connectionObserver panel, because there is no active connection")
  
  # refresh is usually triggered after a separate login, authorized user might explore more data and processes
  assign(x = "data_collection", value = NULL, envir = pkgEnvironment)
  void = list_collections()
  
  assign(x = "process_collection", value = NULL, envir = pkgEnvironment)
  assign(x = "process_list", value = NULL, envir = pkgEnvironment)
  # force refreshing of processes
  
  observer <- getOption("connectionObserver")
  if (!is.null(observer))
    observer$connectionUpdated(type="OpenEO Service", host=con$getHost(),hint="collections")
}

.fill_rstudio_connection_observer = function() {
  observer = getOption("connectionObserver")
  
  if (!is.null(observer)) {
    con = active_connection()
    observer$connectionOpened(type="OpenEO Service",
                              displayName= con$getTitle(), 
                              host=con$getHost(), 
                              listObjectTypes = function() {
                                list(
                                  collection = list(
                                    contains="data"
                                  )
                                )
                              },
                              connectCode = paste0("library(openeo)\n\nconnect(host=\"",paste0(con$getHost(),"/"),"\")"),
                              disconnect = function() {
                                if (is_logged_in()) logout()
                                
                                con = active_connection()
                                if (!is.null(con)) {
                                  con$disconnect()
                                }
                              },
                              listObjects = function(type="collection") {
                                con = active_connection()
                                if (!is.null(con)) {
                                  colls = list_collections(con = con)
                                  cids = names(colls)
                                  types = rep(type,times=length(cids))
                                  
                                  df = data.frame(name=cids,type=types,stringsAsFactors = FALSE)
                                  return(df)
                                } else {
                                  return(list())
                                }
                              },
                              listColumns = function(collection) {
                                if (!is.null(collection)) {
                                  coll = describe_collection(collection=collection)
                                  dim_names = names(dimensions(coll))
                                  
                                  types = sapply(dimensions(coll), function(dim) {
                                    type = dim$type
                                    
                                    if ("axis" %in% names(dim)) {
                                      type = paste0(type,", axis: ",dim$axis)
                                    }
                                    
                                    if ("extent" %in% names(dim)) {
                                      type = paste0(type,", extent: [",dim$extent[1],",",dim$extent[2],"]")
                                    }
                                    
                                    if ("values" %in% names(dim)) {
                                      type = paste0(type,", enum: [",paste(dim$values,collapse=","),"]")
                                    }
                                    
                                    return(type)
                                  })
                                  
                                  df = data.frame(name=dim_names, type=types, stringsAsFactors = FALSE)
                                  
                                  df = rbind(df,list(name="value",type="numeric"))
                                  return(df)
                                }
                              },
                              previewObject = function(collection, ...) {
                                return(data.frame())
                              },
                              connectionObject = con)
  }
}
