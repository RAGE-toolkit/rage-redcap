import os
import requests

# IMPORTANT! Only use this script if you know what you're doing! 
# Note that that the API and tokens are user-specific so not specified in this version. Script available for modification. 

# REDCap API details
# Note that that the recap api and tokens are user-specific so not entered here. Script available for modification. 
REDCAP_API_URL = # replace with url
API_TOKEN =   # replace with your token

# Folder containing FASTA files
# The filenames must be like <sample_id>.fasta (e.g., 2021153276.fasta)
fasta_folder = 'processed_data/split_fasta'  # adjust this

# Variable name for file field
field_name = 'consensus_fasta'

# Loop over all FASTA files in the folder
for filename in os.listdir(fasta_folder):
    if filename.endswith('.fasta'):
        sample_id = os.path.splitext(filename)[0]  # gets filename without extension
        fasta_file_path = os.path.join(fasta_folder, filename)

        print(f'Uploading file for sample_id: {sample_id}')

        # Prepare API request data
        data = {
            'token': API_TOKEN,
            'content': 'file',
            'action': 'import',
            'record': sample_id,
            'field': field_name,
            'event': '',  # leave blank if not longitudinal
            'repeat_instrument': 'sequencing',
            'repeat_instance': 1
        }

        # Open file and upload
        with open(fasta_file_path, 'rb') as file:
            files = {'file': file}
            response = requests.post(REDCAP_API_URL, data=data, files=files)

        # Result
        if response.status_code == 200:
            print(f'✅ Successfully uploaded for sample_id {sample_id}')
        else:
            print(f'❌ Error uploading file for sample_id {sample_id}: {response.status_code}\n{response.text}')

print('Bulk upload complete.')