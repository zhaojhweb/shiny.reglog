#' Emayili email sending handler
#' 
#' @description Default handler function parsing and sending email.
#' Used within object of `RegLogEmayiliConnector` class internally.
#' 
#' @param self R6 object element
#' @param private R6 object element
#' @param message RegLogConnectorMessage which should contain within its data:
#' - process
#' - username
#' - email
#' - app_name
#' - app_address
#' - reset_code (optional for reset code mails)
#' 
#' @return `RegLogEmayiliConnector` message.
#' @family mail handler functions
#' @concept mail_handler
#' @keywords internal

emayili_reglog_mail_handler <- function(self, private, message) {
  
  check_namespace("emayili")
  
  if (!is.character(message$data$process) || length(message$data$process) != 1) {
    stop(call. = F, 
         paste0("The 'RegLogConnectorMessage' object provided to the mailConnector",
                "need to contain character string in its 'process' data field."))
  }
  
  # interpolate subject with elements found
  mail_subject <- string_interpolate(
    x = self$mails[[message$data$process]][["subject"]],
    to_replace = list(
      username = message$data$username,
      email = message$data$email,
      app_name = message$data$app_name,
      app_address = message$data$app_address,
      reset_code = message$data$reset_code
    ))

  # interpolate body with elements found
  mail_body <- string_interpolate(
    x = self$mails[[message$data$process]][["body"]],
    to_replace = list(
      username = message$data$username,
      email = message$data$email,
      app_name = message$data$app_name,
      app_address = message$data$app_address,
      reset_code = message$data$reset_code,
      password = message$data$password
    ))
  
  # parse the email
  mail <- emayili::envelope() |>
    emayili::from(private$from) |>
    emayili::to(message$data$email) |>
    emayili::subject(mail_subject) |>
    emayili::html(content = mail_body)
  
  # and send it!
  message_to_send <- tryCatch({
    private$smtp(mail)
    
    RegLogConnectorMessage(
      message$type,
      process = message$data$process,
      success = TRUE,
      logcontent = paste0(message$data$username, "/", 
                          message$data$email, ":", message$data$process)
    )
    
    }, error = function(e) {
      
      # if error, parse the error message accordingly
      RegLogConnectorMessage(
        message$type,
        process = message$data$process,
        success = FALSE,
        logcontent = paste0(message$data$username, "/",
                            message$data$email, ":", 
                            message$data$process, "|", paste(e, collapse = ";"))
      )
    }
  )
  
  # send the RegLogConnectorMessage
  return(message_to_send)
  
}

#' Emayili custom email sending handler
#' 
#' @description Default handler function parsing and sending email.
#' Used within object of `RegLogEmayiliConnector` class internally. It can
#' send custom emails using subject, body and attachments from 
#' `RegLogConnectorMessage` of type `custom_mail`.
#' 
#' @param self R6 object element
#' @param private R6 object element
#' @param message RegLogConnectorMessage which should contain within its data:
#' - process
#' - username
#' - email
#' - mail_subject
#' - mail_body
#' - mail_attachment (optional, needs to be of class `mailMessageAttachment`)
#' 
#' @return `RegLogEmayiliConnector` message.
#' @family mail handler functions
#' @concept mail_handler
#' @keywords internal

emayili_custom_mail_handler <- function(self, private, message) {
  
  check_namespace("emayili")
  
  if (!is.character(message$data$process) || length(message$data$process) != 1) {
    stop(call. = F, 
         paste0("The 'RegLogConnectorMessage' object provided to the mailConnector",
                "need to contain character string in its 'process' data field."))
  }
  
  # parse the email
  mail <- emayili::envelope() |>
    emayili::from(private$from) |>
    emayili::to(message$data$email) |>
    emayili::subject(message$data$mail_subject) |>
    emayili::html(content = message$data$mail_body)
  
  if (!is.null(message$data$mail_attachment) &&
      isTRUE(class(message$data$mail_attachment) == "mailMessageAttachment")) {
    mail <- mail |>
      emayili::attachment(
        path = message$data$mail_attachment$filepath,
        type = if(!is.null(message$data$mail_attachment$filetype))
          message$data$mail_attachment$filetype else NA,
        cid = if(!is.null(message$data$mail_attachment$cid))
          message$data$mail_attachment$cid else NA,
        name = if(!is.null(message$data$mail_attachment$filename))
          message$data$mail_attachment$filename else NA)
  }
  
  # and send it!
  message_to_send <- tryCatch({
    private$smtp(mail)
    
    RegLogConnectorMessage(
      message$type,
      process = message$data$process,
      success = TRUE,
      logcontent = paste0(message$data$username, "/", 
                          message$data$email, ":", message$data$process)
    )
    
  }, error = function(e) {
    
    # if error, parse the error message accordingly
    RegLogConnectorMessage(
      message$type,
      process = message$data$process,
      success = FALSE,
      logcontent = paste0(message$data$username, "/",
                          message$data$email, ":", 
                          message$data$process, "|", paste(e, collapse = ";"))
    )
  }
  )
  
  # send the RegLogConnectorMessage
  return(message_to_send)
  
}

#' Gmailr send email handler
#' 
#' @description Default handler function parsing and sending register confirmation 
#' email to newly registered user of the package. Used within object of 
#' `RegLogGmailrConnector` class internally.
#' 
#' @param self R6 object element
#' @param private R6 object element
#' @param message RegLogConnectorMessage which should contain within its data:
#' - process
#' - username
#' - email
#' - app_name
#' - app_address
#' - reset_code (optional for reset code mails)
#' 
#' @return `RegLogEmayiliConnector` message.
#' @family mail handler functions
#' @concept mail_handler
#' @keywords internal

gmailr_reglog_mail_handler <- function(self, private, message) {
  
  if (!is.character(message$data$process) || length(message$data$process) != 1) {
    stop(call. = F, 
         paste0("The 'RegLogConnectorMessage' object provided to the mailConnector",
                "need to contain character string in its 'process' data field."))
  }
  
  check_namespace("gmailr")
  
  # interpolate subject with elements found
  mail_subject <- string_interpolate(
    x = self$mails[[message$data$process]][["subject"]],
    to_replace = list(
      username = message$data$username,
      email = message$data$email,
      app_name = message$data$app_name,
      app_address = message$data$app_address,
      reset_code = message$data$reset_code
    ))
  
  # interpolate body with elements found
  mail_body <- string_interpolate(
    x = self$mails[[message$data$process]][["body"]],
    to_replace = list(
      username = message$data$username,
      email = message$data$email,
      app_name = message$data$app_name,
      app_address = message$data$app_address,
      reset_code = message$data$reset_code
    ))
  
  # parse email using gmailr function
  mail <- gmailr::gm_mime() |>
    gmailr::gm_from(private$from) |>
    gmailr::gm_to(message$data$email) |>
    gmailr::gm_subject(mail_subject) |>
    gmailr::gm_html_body(body = mail_body)
  
  # send message using gmailr
  message_to_send <- tryCatch({
    gmailr::gm_send_message(mail)
    
    RegLogConnectorMessage(
      message$type,
      process = message$data$process,
      success = TRUE,
      logcontent = paste0(message$data$username, "/", 
                          message$data$email, ":", message$data$process)
    )
    
  }, error = function(e) {
    
    RegLogConnectorMessage(
      message$type,
      process = message$data$process,
      success = FALSE,
      logcontent = paste0(message$data$username, "/",
                          message$data$email, ":", 
                          message$data$process, "|", paste(e, collapse = ";"))
    )
  }
  )
  
  return(message_to_send)
  
}

#' Gmailr custom email sending handler
#' 
#' @description Default handler function parsing and sending email.
#' Used within object of `RegLogGmailrConnector` class internally. It can
#' send custom emails using subject, body and attachments from 
#' `RegLogConnectorMessage` of type `custom_mail`.
#' 
#' @param self R6 object element
#' @param private R6 object element
#' @param message RegLogConnectorMessage which should contain within its data:
#' - process
#' - username
#' - email
#' - mail_subject
#' - mail_body
#' - mail_attachment (optional, needs to be of class `mailMessageAttachment`)
#' 
#' @return `RegLogGmailrConnector` message.
#' @family mail handler functions
#' @concept mail_handler
#' @keywords internal

gmailr_custom_mail_handler <- function(self, private, message) {
  
  check_namespace("gmailr")
  
  if (!is.character(message$data$process) || length(message$data$process) != 1) {
    stop(call. = F, 
         paste0("The 'RegLogConnectorMessage' object provided to the mailConnector",
                "need to contain character string in its 'process' data field."))
  }
  
  # parse the email
  mail <- gmailr::gm_mime() |>
    gmailr::gm_from(private$from) |>
    gmailr::gm_to(message$data$email) |>
    gmailr::gm_subject(message$data$mail_subject) |>
    gmailr::gm_html_body(body = message$data$mail_body)
  
  if (!is.null(message$data$mail_attachment) &&
      isTRUE(class(message$data$mail_attachment) == "mailMessageAttachment")) {
    mail <- mail |>
      gmailr::gm_attach_file(
        filename = message$data$mail_attachment$filepath,
        type = message$data$mail_attachment$filetype,
        id = message$data$mail_attachment$cid)
  }
  
  # and send it!
  message_to_send <- tryCatch({
    gmailr::send_message(mail)
    
    RegLogConnectorMessage(
      message$type,
      process = message$data$process,
      success = TRUE,
      logcontent = paste0(message$data$username, "/", 
                          message$data$email, ":", message$data$process)
    )
    
  }, error = function(e) {
    
    # if error, parse the error message accordingly
    RegLogConnectorMessage(
      message$type,
      process = message$data$process,
      success = FALSE,
      logcontent = paste0(message$data$username, "/",
                          message$data$email, ":", 
                          message$data$process, "|", paste(e, collapse = ";"))
    )
  }
  )
  
  # send the RegLogConnectorMessage
  return(message_to_send)
  
}

#' Mail attachment data to be handled by mailConnector via `custom_mail` RegLogConnectorMessage
#' 
#' @param filepath path to the file to be attached
#' @param filename name of the file to be used (supported by RegLogEmayiliConnector)
#' @param cid content ID to be used to access in email body
#' @param filetype mime type of the attached file
#' @return mailMessageAttachment object 
#' @export
#' 

mailMessageAttachment <- function(
  filepath,
  filename = NULL,
  cid = NULL,
  filetype = NULL
) {
  
  attachment <- list(
    filepath = filepath,
    filename = filename,
    cid = cid
  )
  
  class(attachment) <- "mailMessageAttachment"
  
  return(attachment)
  
}