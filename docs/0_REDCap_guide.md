---
title: Overview guide
layout: default
---

# 🧬 REDCap Guide for Rabies Virus Sequencing Projects

This guide outlines how to use the REDCap project for managing diagnostic and sequencing metadata across rabies virus projects. It includes how to format metadata, use the data import tool, handle repeating instruments, upload consensus FASTA files, and more.

---

## 📁 1. Project Structure

### 🔹 Forms
- **diagnostic**: Non-repeating form capturing diagnostic metadata (e.g., test results, tissue type).
- **sequencing**: Repeating form for each sequencing event per sample, capturing run metadata and associated summary statistics.

### 🔹 Repeating Instruments
- The **sequencing** form is set as a repeating instrument to support multiple sequencing runs per sample.

### 🔹 Sample ID
- The field **sample_id** serves as the central identifier for all samples.
- It must be present in every record, and is used to link diagnostic and sequencing data across forms and repeats. 
- This field is also used to link to epidemiological metadata held in ODK for Tanzania, and on google sheets for other locations.

---

## 🧾 2. Metadata Dictionary Setup

### ✅ Dropdown Fields with Readable Codes
Use **text-based codes** instead of numeric values to make exports more interpretable.

#### Example — `ngs_analysis_type`:
```
single_run, Single run | merged_runs, Merged runs
```

#### Example — `country`:
```
TZA, Tanzania | KEN, Kenya | UGA, Uganda | PHL, Philippines | NGA, Nigeria | MWI, Malawi
```

---

## 📥 3. Importing Data

### 🔹 Step 1: Download the Data Import Template
1. Go to **Applications > Data Import Tool**.
2. Click **“Download your data import template”** (CSV format).

### 🔹 Step 2: Fill in Your Data
- Use the **CSV template downloaded from REDCap**, which includes the correct column headers (REDCap variable names).
- ⚠️ **Do not rename column headers** — REDCap relies on these internal variable names to match fields correctly.
- For repeating instruments, include the following columns:
  - `sample_id`
  - `redcap_repeat_instrument` (e.g., `sequencing`)
  - `redcap_repeat_instance` (e.g., 1, 2, …)

#### 🧾 Example:
```csv
sample_id,redcap_repeat_instrument,redcap_repeat_instance,ngs_runid,ngs_platform
DOG001,sequencing,1,RUN001,illumina
DOG001,sequencing,2,RUN002,nanopore
```

### ⚠️ Data Standardisation

- For **dropdown fields**, entries **must exactly match** the predefined choices listed in the data dictionary.
- This includes:
  - Using the correct **code format** (e.g., `illumina`, not `Illumina`)
  - Being case-sensitive
  - Avoiding extra spaces or typos

📁 **Download the latest data dictionary** (includes valid codes):  
[Download from git repo](https://github.com/RAGE-toolkit/rage-redcap/blob/main/data_dictionaries/RAGEredcap_DataDictionary.csv)

- Check predefined choices in **column F**, titled *“Choices, Calculations, OR Slider Labels”*.

> 🔍 Incorrect or unrecognised values will cause the import to fail or silently skip affected fields.

### 🔹 Step 3: Import the Data
- Return to **Applications > Data Import Tool**.
- Upload your completed CSV file.
- REDCap will validate the file and give you a chance to review before confirming the import.

---

## 📤 4. Exporting and Merging Data

REDCap exports data from each **instrument form** in **separate rows**, so you’ll typically see **two rows per sample** — one for `diagnostic`, and one (or more) for `sequencing` since it’s a repeating instrument.

> ⚠️ REDCap does **not** automatically merge data across instruments during export.

If you need a combined dataset (e.g. one row per sample with all diagnostic and sequencing fields), this must be done **after export**, using tools like **R** or **Python**.

> 🧪 A basic R script for merging REDCap export files is available — contact the project lead if needed.

### 🔹 Exporting Data

There are two main ways to export data from REDCap depending on your needs:

---

### 📦 Option 1: Full Data Export (All Records and Fields)

1. Go to **Applications > Data Exports, Reports, and Stats**.
2. Next to **All data (all records and fields)**, click on **“Export Data”** under *View/Export Options*.
3. Choose the export format that suits your needs — usually CSV:
   - **Raw**: Exports the internal REDCap codes (e.g., `0`, `1`, `illumina`)
   - **Labels**: Exports the human-readable labels (e.g., `Negative`, `Positive`, `Illumina`)

> ℹ️ **Note:** In this project, **Raw** and **Label** exports will usually look the same, since we use descriptive text-based codes in the data dictionary (e.g., `illumina`, `nanopore`).

4. Click **Export File** to download the full dataset.
5. The export will include only records within your assigned **Data Access Group (DAG)** and respect your **user role’s export permissions**. 

> 💡 **Tip:** Use **Raw** format if you plan to re-import or process the data programmatically. Use **Labels** for quick review or sharing.

> 🔐 Export will respect your assigned **User Access Group (DAG)** and any **data access permissions** (e.g., de-identification settings).

---

### 🧩 Option 2: Custom Report-Based Export

1. Go to **Data Exports, Reports, and Stats**.
2. Click **“Create New Report”** or select an existing one.
3. Choose only the fields relevant to your task (e.g., diagnostics only, or specific sequencing metrics).
4. Save and run the report.
5. Click **“Export Data”** and select your preferred CSV format.

> 💡 Custom reports are useful for focused tasks or when working with subsets of data (e.g., per country, by seq run, etc.).

---


### 🔹 Merging in R / Python

**In R**:
```r
diagnostic <- read_csv("MyData_DATA.csv")
sequencing <- read_csv("MyData_sequencing.csv")
merged <- sequencing %>% left_join(diagnostic, by = "sample_id")
```

---

## 📎 5. Uploading Consensus FASTA Files

### 🔹 Overview
The REDCap project includes a `file` upload field called **`consensus_fasta`** within the **sequencing** form. This allows users to attach a genome consensus sequence (FASTA format) to each sequencing entry.

### 🔹 Upload Method
- Files are typically uploaded **manually** via the record’s **data entry page**.
- This is the recommended method for most users to ensure correct file-to-record matching.
- This means files can't be uploaded in bulk so it can be a time-consuming process with many files. 
- Bulk uploads can be facilitated via API but option in only for advanced users (see below).

### 🔹 Recommended Workflow
1. **Bulk import sequencing metadata** using the data import tool, leaving the `consensus_fasta` column empty.
2. Open each record in the **sequencing form** via the web interface.
3. Upload the corresponding FASTA file using the `consensus_fasta` field.

> 💡 Tip: Ensure the FASTA file name clearly matches the `sample_id` to avoid confusion during upload.


### 🔐 ⚠️ Advanced Users Only: API-Based File Uploads (Restricted Access)

> 🚫 **Not for general users**  
> This method is intended **only for advanced users** with scripting experience and a clear understanding of REDCap's API. Misuse can result in data corruption.

REDCap **does support file uploads via its API**, but access is **restricted and tightly controlled**.

If you have a large number of consensus FASTA files to upload and wish to automate the process:

- You **must request approval and guidance** from the project lead.
- API tokens and script templates will only be provided to experienced users on a case-by-case basis.
- All uploads must follow strict file-naming and data-matching conventions.

📬 **To request access**, contact:

```
Kirstyn Brunker
Email: kirstyn.brunker@glasgow.ac.uk
Subject: Request for REDCap API access for consensus_fasta upload
```

---

## 📦 6. Batch Downloading FASTA Files

Consensus FASTA files can be downloaded in bulk via a REDCap **report**:

- Navigate to **Reports > Per country fasta files**.
- This report displays:
  - Sample ID
  - Repeating instrument and instance
  - Country of origin
  - Associated `consensus_fasta` file (if uploaded)
- You will only see records belonging to the **Data Access Group (DAG)** you have been assigned to (e.g. *Philippines*, *East Africa*, etc.).
- Note: Each sample may appear in **two rows** because this report pulls data from **both the diagnostic and sequencing forms**. This is expected behaviour and helps show linked information from both instruments.

### 🔹 Downloading Files

- At the top right of the table, look for the option:  
  **“Download files (zip)”**
- Clicking this will generate and download a ZIP file containing all consensus FASTA files linked to the visible records in the report.

### 🛠 If the download option is missing:
Check the following:
- Files have actually been uploaded
- Your user role includes **file export rights**

> 💡 Tip: If you're unsure which DAG you're in or need access to another group, contact the project admin.

---
