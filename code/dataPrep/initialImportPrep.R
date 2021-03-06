################################
### Chuck Lorre Vanity Cards ###
###  Initial Import & Clean  ###
################################

library(rvest); library(dplyr); library(stringr)

### Getting the links for each text ###

links = read_html("http://www.chucklorre.com/index.php") %>% 
  html_nodes("#navigation a") %>% 
  html_attr("href") %>% 
  paste0("http://www.chucklorre.com/", .)

# The following function goes through each link and extracts the card text. 

getTextOnly = function(x){
  initialLink = read_html(x)
  linkNodes = html_nodes(initialLink, "#content p")
  htmlText = html_text(linkNodes)
  htmlText = as.list(htmlText)
}

# To make things quicker, we are going to use the parallel package.
# It take about 3 minutes otherwise and nobody has that kind of time.

library(parallel)

cl = makeCluster(3) # I always leave one open; be sure to change this to something that works for you

clusterExport(cl, c("links"))

clusterEvalQ(cl, library(rvest))

cardText = parLapply(cl, links, getTextOnly)

stopCluster(cl)

### Text Cleaning ###

# The two cleaning lines could be handled in one line, but sometimes it makes
# sense (to me) to split apart stuff with a lot of patterns in it.

textCleaning = function(x){
  cleaned = lapply(x, str_replace_all, pattern = "\n|\t|\"|?", replacement = " ")
  cleaned = lapply(cleaned, str_replace_all, pattern = "\\s\\s", replacement = " ")
  cleaned
}

# The following line will collapse all of the the individual elements down. 
# Because of the way it was brought in, everything with a "p" tag was its own 
# list element.  Since we are going to be doing some text analysis, we need
# the text for each card (i.e., document) to be together.

vanityText = lapply(cardText, paste, collapse = "") %>% 
  unlist %>% 
  data.frame(stringsAsFactors = FALSE)

names(vanityText) = "text"

# Now, we need to split the card text and the air date. We could just strip it 
# out, but we are going to use the date later on. 

vanityText = str_split_fixed(vanityText$text, "1st Aired:", 2) %>% 
  data.frame(stringsAsFactors = FALSE) %>% 
  rename(text = X1, date = X2)

# Now we need to do some cleaning up of the dates. They are formatted 
# like, "26 October 2015", but we need them to be POSIX values.

vanityText$date = vanityText$date %>% 
  str_trim(side = "both") %>%  # Just to trim up any whitespace
  str_extract("[0-9]+ [A-Za-z]+ [0-9]+") %>% # A few entries have multiple dates, so taking the first one
  lubridate::parse_date_time("%d%B%y") # We need to specify the date string to go POSIX

# save(cardText, vanityText, file = "data/chuckLorreText.RData")

# write.csv(vanityText, file = "data/chuckLorreText.csv", row.names = FALSE)
