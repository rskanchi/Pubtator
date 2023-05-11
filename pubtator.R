
loadRequiredPackages <- function(required.packages){
  # what packages are not installed? 
  packages.not.installed <- required.packages[!(required.packages %in% installed.packages()[,"Package"])]
  # install if any not installed already
  if(length(packages.not.installed)>0) {install.packages(packages.not.installed, repos = "http://cran.us.r-project.org")}
  lapply(required.packages, require, character.only = TRUE)
} # end of function loadRequiredPackages

# function to create a template file
# this file will be read in each iteration to create the js and html files for the search pairs
makewebScrapeFile <- function(){
  fileConnection <- file("scrape.js")
  # lines start
  writeLines(c("var url =", 
               "var page = new WebPage()",
               "var fs = require('fs');",
               "page.open(url, function (status) {",
               " just_wait();",
               "});",
               
               "function just_wait() {",
               "  setTimeout(function() {",
               "    fs.write('search.html', page.content, 'w');",
               "    phantom.exit();",
               "  }, 2500);",
               "};"
  ),
  fileConnection)
  close(fileConnection)
} # end of making the file scrape.js


# function to return the frequency of publications for a pair of search terms str1 and str2
getPairFreq <- function(str1, str2){
  options(stringsAsFactors = FALSE)
  main_url <- "https://www.ncbi.nlm.nih.gov/research/pubtator/?view=docsum&query="
  # change the url to update search terms in the js file
  url <- paste0(main_url, '"', str1, '"+"' , str2, '"', sep = "")
  lines <- readLines("scrape.js", warn = FALSE)
  lines[1] <- paste0("var url ='", url ,"';")
  htmlFile <- gsub(" ", "", paste(str1, str2, ".html"))
  lines[9] <- paste0("    fs.write('", htmlFile, "', page.content, 'w');")
  jsFile <- gsub(" ", "", paste(str1, str2, ".js"))
  writeLines(lines, jsFile)
  
  # Download webpage and save a html version locally
  system(paste("phantomjs", jsFile))
  # use Rvest to scrape the downloaded website
  scrape_res <- xml2::read_html(htmlFile)
  
  flag_text <- rvest::html_text(rvest::html_nodes(scrape_res, ".s12"))
  flag <- grepl("No matching publications", flag_text, fixed = TRUE) 
  if (sum(flag)  == 1) { n <- 0 } else {
    # sum(flag) == 0 then at least one publication
    nText <- rvest::html_text(rvest::html_nodes(scrape_res, ".s12 .ng-isolate-scope:nth-child(1) div")[1])
    flag_multiple <- grepl("Showing 1 to", nText, fixed = TRUE)
    if (flag_multiple) {
      # >1 : list of publications
      # compute the total number of publications
      n <- strsplit(nText, "\\s+")[[1]][6]
      n <- as.numeric(n)
    } else {n <- 1} # end of if in flag_multiple
  } # end of if in flag
  
  # remove the js and html files
  file.remove(jsFile)
  file.remove(htmlFile)
  
  return(n)
} # end of getPairFreq


getPubtatorFrequencies <- function(datafile, # data with two columns of search strings
                                   fileId = NULL # output file identifier
                                   ){
  # function to install any packages not already installed; and load all the required packages
  # input: a vector of R packages
  loadRequiredPackages(required.packages = c("rvest", "doParallel", "parallel", "foreach", "rvest", "xml2", "openxlsx"))
  
  filename <- paste("pubtator_output_", fileId, "_", format(Sys.Date(), "%m_%d_%Y"), ".xlsx", sep = "")
  
  # data: columns from the data file as row and column search terms
  data <- read.csv(file = datafile, na.strings = c("", " ", "NA"))
  str1_terms <- data[,1]
  str2_terms <- data[,2]
  
  # if different number of search terms in the two columns, remove the NAs that are read
  str1_terms <- str1_terms[!is.na(str1_terms)]
  str2_terms <- str2_terms[!is.na(str2_terms)]
  
  # remove any duplicated terms
  str1_terms <- unique(str1_terms) 
  str2_terms <- unique(str2_terms)
  
  makewebScrapeFile()
  
  combinations <- expand.grid(str1_terms, str2_terms, stringsAsFactors = FALSE)
  colnames(combinations) <- c("string1", "string2")
  
  combinations$frequency <- apply(combinations, 1, FUN = function(s){
    cat("search terms: ", s[1], " || ", s[2], "\n")
    getPairFreq(str1 = s[1], str2 = s[2])
  })
  
  combinations <- data.frame(combinations, row.names = NULL)
  combinations$frequency <- as.numeric(combinations$frequency)
  wide_form <- matrix(combinations$frequency, nrow = length(str1_terms), ncol = length(str2_terms), 
                      byrow = FALSE, dimnames = list(str1_terms, str2_terms))
  
  wide_form <- wide_form[order(rowSums(wide_form), decreasing = TRUE),]
  wide_form <- wide_form[, order(colSums(wide_form), decreasing = TRUE)]
  
  # results in excel
  write.xlsx(list("frequency" = wide_form, "long_form" = combinations), file = filename, overwrite = TRUE, 
             rowNames = c(TRUE, FALSE), colNames = TRUE, colWidths = "auto", 
             headerStyle = createStyle(textDecoration = "Bold", textRotation = 45))
  
  
} # end of function getPubtatorFrequencies



