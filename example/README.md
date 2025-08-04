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
