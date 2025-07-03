from Bio import SeqIO

def check_duplicates_in_fasta(fasta_file):
    """
    Check for duplicate sequence IDs in a FASTA file.
    
    Parameters:
    fasta_file (str): Path to the input FASTA file.
    
    Returns:
    list: List of duplicate sequence IDs.
    """
    # Create a set to store unique sequence IDs
    seen_ids = set()
    duplicates = set()

    # Parse the FASTA file
    for record in SeqIO.parse(fasta_file, "fasta"):
        if record.id in seen_ids:
            duplicates.add(record.id)  # Add to duplicates if already seen
        else:
            seen_ids.add(record.id)  # Add to seen set if it's the first occurrence
    
    return list(duplicates)

# Example usage
fasta_file = "/Users/kirstyn.brunker/Downloads/East_africa_consensus/all.fasta"  # Replace with your FASTA file path
duplicates = check_duplicates_in_fasta(fasta_file)

if duplicates:
    print(f"Found duplicate sequence IDs: {duplicates}")
else:
    print("No duplicates found.")