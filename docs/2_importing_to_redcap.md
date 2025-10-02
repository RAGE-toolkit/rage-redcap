---
title: Data import
layout: default
---

# RAGE-redcap Data and Sequence Import Instructions

This guide provides step-by-step instructions for preparing and importing metadata and sequence data into RAGE-redcap.

---

## 1. Metadata Import

### Download Import Template
1. Go to **Applications > Data Import Tool** in REDCap.
2. Click **Download Your Data Import Template** to get the Excel template.

### Complete Template
- Fill in the template using the **latest data dictionary** as reference. 
- Adhere to approved choices for dropdown or radio fields; only these will be accepted by the database.
- Not all fields are relevant for every user — complete what applies.
- Latest data dictionary can be obtained:
  - From REDCap: **Project Home > Design > Download Data Dictionary**
  - From GitHub: [RAGE REDCap Data Dictionary](https://github.com/RAGE-toolkit/rage-redcap/blob/main/data_dictionaries/RAGEredcap_DataDictionary.csv)

### Prepare Metadata
1. Save the completed template with a suitable filename.
2. Use the **rabvRedcapProcessing R tool** to prepare the data for REDCap import: [rabvRedcapProcessing GitHub](https://github.com/RAGE-toolkit/rabvRedcapProcessing)
3. Run the `checkScripts.R` script to process your imported sheet and generate sequencing and diagnostic forms ready for REDCap: [checkScripts.R](https://github.com/RAGE-toolkit/rabvRedcapProcessing/blob/main/tools/checkScripts.R)
  - Edit only the input file paths to match your data.
4. Visually inspect the outputs.

### Important Notes
- **Duplicate sequencing events:** Carefully check your import list against the latest REDCap dataset to identify any repeat sequencing events. Manually adjust the `redcap_repeat_instance` for these repeats and remove duplicates from the diagnostic sheet to prevent overwriting existing records. Assign repeat instances in the new data consistently to ensure accurate tracking and integration.
- Review REDCap import warnings carefully; data that may be overwritten is highlighted in red.

### Import Metadata
1. Go to **Applications > Data Import Tool**.
2. Select your import file (one at a time for diagnostic and sequencing forms).
3. Leave other settings as default and click **Upload File**.
4. Verify the import summary and confirm.

---

## 2. Sequence Data Import

### Prepare Environment
Before running the sequence import scripts, set up the conda environment included in this repository.

1. Create the environment from the provided `environment.yml` file:
   ```bash
   conda env create -f environment.yml
   ```
2.    Activate the environment:
   ```bash
conda activate rage-redcap
   ```
3.    Verify installation:
   ```bash
python --version
   ```
### Prepare Sequences
1. Ensure metadata has been imported first to associate sequences with records.
2. Obtain consensus FASTA sequences from your latest run.
3. Concatenate sequences from artic-rabv pipeline output: `results/concatenate/concat_genome.fasta`.

### Split and Rename FASTA Files
1. Use `multi_to_single_fasta.py` to split the multi-FASTA into individual FASTA files: `python3 multi_to_single_fasta.py`
2. Edit input/output paths in the script as required.
3. Ensure filenames correspond to sample IDs from FASTA headers.
4. Negative controls: Copy and rename manually as `negative_runname__runname__instance1.fasta` and edit internal FASTA headers to match.

### Match Metadata and Rename for Import
1. Run `redcap-prepareFASTA.R`
   - Edit `metadata_file`, `fasta_dir`, and `output_dir` filepaths.
   - Script matches sequences to REDCap metadata and renames FASTA files as `sampleID__runname__instanceX.fasta`.
2. Verify all renamed FASTA files and negative controls.

### Upload Sequences to REDCap
1. Use `bulk_upload_fasta_repeatInstances.py`: `python3 bulk_upload_fasta_repeatInstances.py`
2. Edit input folder path to the renamed FASTA directory.
3. Ensure the REDCap API URL points to the correct project version (updates may change the endpoint).
4. Monitor command-line output for successful uploads.
5. If files do not appear, check API version and repeat instances.

### Additional Notes
- Always verify sequencing records are not accidentally overwritten.
- Assumes you have REDCap API access with local environment files; contact project lead if not set up.
- REDCap provides informative error messages during import; use these to correct formatting or repeat instance issues before re-importing.
