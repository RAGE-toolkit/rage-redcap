import os
from Bio import SeqIO

fasta_folder = "/Volumes/kb4/philippines/split_fasta"  # Update this path to your folder with FASTA files

for filename in os.listdir(fasta_folder):
    if filename.endswith(".fasta"):
        filepath = os.path.join(fasta_folder, filename)
        print(f"🔍 Checking: {filename}")
        try:
            # Open file in text mode
            with open(filepath, "r") as input_handle:  # Change 'rb' to 'r'
                records = list(SeqIO.parse(input_handle, "fasta"))
            print(f"✅ {filename} parsed successfully")
        except Exception as e:
            print(f"❌ ERROR in file: {filename}")
            print(f"   {type(e).__name__}: {e}")