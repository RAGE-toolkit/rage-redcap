## 🧪 Examples

Examples of data import files and common issues encountered during REDCap uploads.

### 📄 `test-import_1`

This example contains **a single row** for a record, with information filled in for both the **Diagnostic** and **Sequencing** instruments.

**Issues:**

- The **Sequencing** form is a **repeating instrument**, so this row must include the fields:
  - `redcap_repeat_instrument`
  - `redcap_repeat_instance`
- Each instrument's data must appear in a **separate row**. REDCap cannot process information for both a repeating and non-repeating instrument in the same row.

---

### 📄 `test-import_2`

In this example, the record is split across **two rows**, with each row containing information for **only one instrument**. Irrelevant columns are left blank.

**Key points:**

- **Sequencing** (a repeating instrument):
  - Must include `redcap_repeat_instrument` and `redcap_repeat_instance`.
- **Diagnostic** (a non-repeating instrument):
  - Should **not** include values for `redcap_repeat_instrument` and `redcap_repeat_instance`.
  - To upload both instruments for the same record, the data must be split across two rows (like in this example), or across **two separate files** — one for **Diagnostic**, and one for **Sequencing**.

> ✅ Our R code automates this splitting process, generating correctly formatted import files for each instrument.

**Issues:**

- On import to REDCap, an error appears for the field `sample_tissuetype`:  
  *"The value is not a valid category for sample_tissuetype."*
- In this instance, the value entered (`brain`) does not match the format defined in the data dictionary.
- For fields with predefined choices, your data **must match the exact value** listed in the dictionary.
- In this case, `brain` should be capitalised as `Brain`.

> ✅ Our R code helps clean and standardise metadata to fix common issues like this.  However, it is still the user's responsibility to prepare the metadata correctly from the start.  The R code can assist with formatting — but it won't catch every error!

### 📄 `test-import_3`

This version is correctly formatted and should upload to REDCap without any issues.

Once imported, you can view the record by navigating to **Add/Edit Records** in REDCap and searching for the relevant sample ID.


### 📄 `received_data_1`  

This is a more comprehensive - and quite realistic! - example of the data you might recieve or recorded yourself. Note that some of the columns in this example might not been data relevant to sequence metadata (it might be epi data, which is not stored in our redcap but is still important to keep elsewhere) or may be relevant information with the wrong or slightly different column name. Formats or entries may not be correct - it is important they match what is specified in the data dictionary. 
Can you prepare a data import from this data using the instructions in the data import secction here: https://rage-toolkit.github.io/rage-redcap/2_importing_to_redcap.html

### 🧬  `received_seq_1`   

This is a multifasta file that contains the consensus sequences associated with received_data_1. Before these can be uploaded via the API interface they must be prepared: 
https://rage-toolkit.github.io/rage-redcap/2_importing_to_redcap.html
