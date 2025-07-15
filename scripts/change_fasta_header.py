import os
from Bio import SeqIO

# Folder containing the fasta files
fasta_folder = "/Volumes/kb4/philippines/manually_found_fasta"  # 🔁 Change this to your folder path

# Loop through all .fasta files in the folder
for filename in os.listdir(fasta_folder):
    # Skip hidden files (e.g., those starting with ._)
    if filename.startswith('._') or not filename.endswith(".fasta"):
        continue

    filepath = os.path.join(fasta_folder, filename)
    sample_id = os.path.splitext(filename)[0]

    try:
        # Read in sequences
        records = list(SeqIO.parse(filepath, "fasta"))
        for record in records:
            # Rename header to filename without extension
            record.id = sample_id
            record.name = sample_id
            record.description = ""  # Remove the description part

        # Overwrite the original file with new header
        with open(filepath, "w") as output_handle:
            SeqIO.write(records, output_handle, "fasta")

        print(f"✅ Renamed header in {filename} to {sample_id}")

    except Exception as e:
        print(f"❌ ERROR in file: {filename}")
        print(f"   {type(e).__name__}: {e}")