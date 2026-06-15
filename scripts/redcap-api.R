#  install.packages("redcapAPI")

library(redcapAPI)
rcon <- redcapConnection(
  url = "https://cvr-redcap.mvls.gla.ac.uk/redcap/api/",
  token = Sys.getenv("REDCAP_RAGE_TOKEN")
)
rcon
Sys.getenv("REDCAP_RAGE_TOKEN")
