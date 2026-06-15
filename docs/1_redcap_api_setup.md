---
title: API Setup
layout: default
---

# RAGE-REDCap API Setup

This guide explains how to securely configure access to the RAGE-REDCap API using the `redcapAPI` R package. The recommended approach uses environment variables to ensure secure, reproducible, and platform-independent authentication.

---

## 🔐 API Access

To access the RAGE-REDCap project, you must have an API token.

If you do not have a token, contact the project lead:
kirstyn.brunker@glasgow.ac.uk

To retrieve your token:

1. Log in to REDCap.
2. Navigate to **Applications → API**.
3. Copy your personal API token for use in the next step.

---

## ⚙️ Secure Configuration (Recommended)

We recommend storing your API token as an environment variable rather than embedding it in scripts or using system keyrings.

### Step 1 — Create or edit your `.Renviron` file

In R, run:

```r
file.edit("~/.Renviron")
```

Add the following line:   
```r
REDCAP_RAGE_TOKEN=your_api_token_here
```

Save the file and restart R.

### Step 2 — Verify your configuration

Check that the token is available:
```r
Sys.getenv("REDCAP_RAGE_TOKEN")
```
If configured correctly, this will return your API token.

## 🚀 Connecting to REDCap

Create a REDCap connection using the redcapAPI package:
```r
library(redcapAPI)

rcon <- redcapConnection(
  url = "https://cvr-redcap.mvls.gla.ac.uk/redcap/api/",
  token = Sys.getenv("REDCAP_RAGE_TOKEN")
)
```
## 🔁 Recommended Workflow

Wrap the connection in a helper function:
```r
get_rcon <- function() {
  redcapConnection(
    url = "https://cvr-redcap.mvls.gla.ac.uk/redcap/redcap_v17.1.1/API/",
    token = Sys.getenv("REDCAP_RAGE_TOKEN")
  )
}
```
Usage:
```r
rcon <- get_rcon()
```