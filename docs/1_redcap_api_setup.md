---
title: API Setup
layout: default
---

# RAGE-REDCap API Setup

This guide explains how to securely configure access to the RAGE-REDCap API using the `redcapAPI` R package.

The recommended approach uses environment variables to ensure secure, reproducible, and platform-independent authentication.

---

## 🔐 API Access

To access the RAGE-REDCap project, you will need an API token.

If you do not already have a token, contact the project lead:

**kirstyn.brunker@glasgow.ac.uk**

---

### Obtaining your API token

1. Log in to REDCap
2. Navigate to **Applications → API**
3. Copy your personal API token

⚠️ Treat this token as sensitive information. Do not commit it to GitHub or share it in scripts.

---

## ⚙️ Secure Configuration (Recommended)

We strongly recommend storing your API token as an environment variable using `.Renviron`.  
This avoids hard-coding credentials and improves reproducibility across systems.

---

### Step 1 — Clone the repository

If you have not already cloned the repository:

```bash
git clone https://github.com/RAGE-toolkit/rage-redcap ~/GitHub/rage-redcap
```
Alternatively, use GitHub Desktop or another GUI client.

## Step 2 — Open the R project

Open the R project file:   

~/GitHub/rage-redcap/rabv_redcap.Rproj

Using an R project ensures that:
- relative file paths work correctly
- the working directory is set automatically
- scripts run consistently across machines

## Step 3 — Create or edit your `.Renviron` file

In R, run:

```r
file.edit("~/.Renviron")
```
Add the following line:   

REDCAP_RAGE_TOKEN=your_api_token_here

Replace your_api_token_here with your actual REDCap API token.

Save the file and close it.

⚠️ Important: You must restart R after editing .Renviron for changes to take effect.

## Step 4 — Verify configuration

After restarting R, confirm that the environment variable is available:
```r
Sys.getenv("REDCAP_RAGE_TOKEN")
```
If configured correctly, this will return your API token.

If it returns an empty string (""), the environment variable has not been set correctly or R has not been restarted.

## Step 5 — Connect to REDCap

Once the token is available, you can establish a connection using redcapAPI:
```r
library(redcapAPI)

rcon <- redcapAPI::redcapConnection(
  url   = "YOUR_REDCAP_URL",
  token = Sys.getenv("REDCAP_RAGE_TOKEN")
)
```

Expected output

If successful, you should see:
REDCap API Connection Object
