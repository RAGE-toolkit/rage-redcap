---
title: RAGE-redcap API Setup
layout: default
---

# RAGE-redcap API Setup

This guide explains how to securely configure access to the RAGE-redcap API using the `redcapAPI` R package.

---

## API Access
Ensure you have been granted an API token for RAGE-REDCap. If not, contact the project lead: kirstyn.brunker@glasgow.ac.uk.  

- Log in to REDCap, go to **Applications > API**, and copy your API token for the next steps.

## Using the `redcapAPI` Package
1. Open the `redcap-api.R` script located in the `R_scripts` directory of this repository.
2. Run the code, which should look like this:
```R
unlockREDCap(
  c(rcon = 'rage-redcap'),  
  keyring = "rage-redcap",
  envir = globalenv(),
  url = 'https://cvr-redcap.mvls.gla.ac.uk/redcap/redcap_v15.5.15/API/'
)
```
3.	A prompt will appear asking you to create a new password for the rage-redcap keyring. Enter a secure password and press OK.
	4.	You will then be prompted to enter your API token. Paste the token you copied from REDCap.
5.	This establishes your API connection to the REDCap data.
6.	In future sessions, you will be prompted for the keyring password. Keep a record of it.
7.	For any scripts that need to access REDCap, simply source this script at the start:
```R
source("R_scripts/redcap-api.R")
```
