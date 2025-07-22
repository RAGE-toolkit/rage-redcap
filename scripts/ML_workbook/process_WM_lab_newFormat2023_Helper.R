

library(purrr)
# Diagnostic rule
create_diagnostic_result_rule <- function(df) {
  n <- nrow(df)
  
  get_column <- function(col, default = NA_character_, numeric = FALSE) {
    if (col %in% names(df)) {
      val <- df[[col]]
      val[val == ""] <- NA
      if (numeric) suppressWarnings(as.numeric(val)) else val
    } else {
      rep(default, n)
    }
  }
  
  lft       <- get_column("lateral_flow_test")
  rt        <- get_column("rtqpcr", default = NA_real_, numeric = TRUE)
  hmp       <- get_column("hmpcr_n405")
  fat_test  <- get_column("fat")
  drit_test <- get_column("drit")
  
  purrr::pmap_chr(
    list(lft, rt, hmp, fat_test, drit_test),
    function(lft, rt, hmp, fat, drit) {
      all_missing <- all(is.na(c(lft, rt, hmp, fat, drit)))
      if (all_missing) return(NA_character_)
      
      # FAT/DRIT override
      if (!is.na(fat) || !is.na(drit)) {
        if (fat == "Positive" || drit == "Positive") return("Positive")
        if ((fat == "Negative" || drit == "Negative") &&
            (!is.na(lft) && lft == "1" || !is.na(rt) && rt < 32 || hmp %in% c("0", "1")))
          return("Positive")
        return("Negative")
      }
      
      # LFT
      if (!is.na(lft)) return(ifelse(lft == "1", "Positive", "Negative"))
      
      # RT-qPCR
      if (!is.na(rt)) {
        if (rt < 32) return("Positive")
        if (rt <= 36) return("Inconclusive")
        return("Negative")
      }
      
      # HMPCR
      if (!is.na(hmp)) return(ifelse(hmp %in% c("0", "1"), "Positive", "Negative"))
      
      # Fallback
      NA_character_
    }
  )
}


# Specify the columns that belong to each instrument (adjust based on actual columns)

data_dict <- read.csv("./data_dictionaries/RABVlab_DataDictionary_2025-07-16.csv")

required <- c("sample_id", "redcap_repeat_instrument", "redcap_repeat_instance", "redcap_data_access_group")

diagnostic_columns <- data_dict %>%
  filter(Form.Name == "diagnostic") %>%
  pull(Variable...Field.Name) %>%
  union("sample_id") # No "redcap_repeat_instrument" & "redcap_repeat_instance" in diagnostic form

sequencing_columns <- data_dict %>%
  filter(Form.Name == "sequencing") %>%
  pull(Variable...Field.Name) %>%
  union(required)


# parse a single choice‐string into a named vector (dynamically create dictionaries)
read_and_parse_dict <- function(dictPath) {
  data_dict <- read.csv(dictPath, stringsAsFactors = FALSE)
  
  # Helper to parse single string of "code, label | code, label"
  parse_dict <- function(choice_str) {
    pieces <- stringr::str_split(choice_str, "\\|")[[1]] %>% stringr::str_trim()
    # key values
    kv <- purrr::map(pieces, ~{
      parts <- stringr::str_split_fixed(.x, ",", 2)
      code  <- stringr::str_trim(parts[1])
      label <- stringr::str_trim(parts[2])
      setNames(label, code)  # named vector: names = code, value = label
    })
    unlist(kv)
  }
  
  dicts <- data_dict %>%
    dplyr::filter(.data$Choices..Calculations..OR.Slider.Labels != "") %>%
    dplyr::mutate(
      dict = purrr::map(.data$Choices..Calculations..OR.Slider.Labels, parse_dict)
    ) %>%
    # dplyr::select(field = .data$Variable...Field.Name, dict) %>% # deprecated
    dplyr::select("Variable...Field.Name", "dict") %>%
    tibble::deframe()
  
  # Define country dictionary
  country_dict  <- dicts[["country"]]
  
  # process this further to take either country full name or short
  # parse out codes and names
  entries <- names(country_dict)
  values  <- unname(country_dict)
  parts   <- strsplit(values, ":\\s*")
  codes   <- sapply(parts, `[`, 1)
  names_  <- sapply(parts, `[`, 2)
  
  
  # build a lookup that maps both code→value and name→value
  country_dict <- c(
    # setNames(codes, entries),
    setNames(names_, entries)
  )
  
  dicts[["country"]] <- country_dict
  
  
  return(dicts)
}


scan_mismatched_levels <- function(dayta, dicts, col_to_check) {
  # Check if the column is in the dictionary
  if (!col_to_check %in% names(dicts)) {
    message(glue::glue("⚠️ '{col_to_check}' is not a coded field (i.e., not constrained in the dictionary)."))
    return(invisible(NULL))
  }
  
  # Extract values from the column
  column_values <- unique(as.character(dayta[[col_to_check]]))
  
  # Get allowed labels from dict
  allowed_labels <- unname(dicts[[col_to_check]])
  
  # Identify mismatched values
  not_in_dict <- setdiff(column_values, allowed_labels)
  
  # Reporting
  if (length(not_in_dict) == 0) {
    message(glue::glue("✅ All values in '{col_to_check}' are valid and match the dictionary."))
  } else {
    message(glue::glue("❌ The following values in '{col_to_check}' are not listed in the dictionary:\n - ",
                       paste(not_in_dict, collapse = ", ")))
    
    # Check for fallback categories
    if (any(c("Unknown", "Other") %in% allowed_labels)) {
      fallback <- allowed_labels[allowed_labels %in% c("Unknown", "Other")]
      message(glue::glue("ℹ️ These values will be classed as: {paste(fallback, collapse = ' or ')}"))
    }
  }
  
  invisible(not_in_dict)
}


capitalize_first_word <- function(x) {
  x <- str_trim(tolower(x))
  ifelse(
    is.na(x) | x == "",
    x,
    paste0(toupper(substr(x, 1, 1)), substr(x, 2, nchar(x)))
  )
}


recode_data <- function(dicts, dayta) {
  recoded_data <- dayta
  
  for (col in intersect(names(dicts), names(dayta))) {
    dict <- dicts[[col]]
    
    # Reverse the dictionary: label → code
    label_to_code <- setNames(names(dict), dict)
    
    # Coerce and match based on lowercase labels
    original_vals <- as.character(dayta[[col]])
    matched_vals <- label_to_code[original_vals]
    
    # Warn if any unmatched
    if (any(is.na(matched_vals) & !is.na(original_vals))) {
      unmatched <- unique(original_vals[is.na(matched_vals)])
      message(glue::glue("⚠️ Unmatched values in `{col}`: {paste(unmatched, collapse = ', ')}"))
    }
    
    recoded_data[[col]] <- matched_vals
  }
  
  return(recoded_data)
}

