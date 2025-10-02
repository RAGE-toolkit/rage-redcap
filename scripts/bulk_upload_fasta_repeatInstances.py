import os
import re
import requests
from dotenv import load_dotenv

# Load environment variables from .env
load_dotenv()

# Get REDCap API config from environment
REDCAP_API_URL = os.getenv('REDCAP_API_URL')
API_TOKEN = os.getenv('REDCAP_API_TOKEN')

# Safety check
if not REDCAP_API_URL or not API_TOKEN:
    raise ValueError("Missing REDCAP_API_URL or REDCAP_API_TOKEN in environment variables.")

# Folder containing FASTA files
fasta_folder = 'Addfilepath'

# REDCap field name for the file upload
field_name = 'consensus_fasta'

# Regex pattern for filenames like: H-23-011Sa-12__run12_23__instance1.fasta
pattern = r'^(?P<sample_id>.+?)__+(?P<run_id>.+?)__+instance(?P<instance>\d+)\.fasta$'

# Counters
total_files = 0
uploaded_count = 0

# Loop through files in folder
for filename in os.listdir(fasta_folder):
    if not filename.endswith('.fasta'):
        continue

    total_files += 1
    match = re.match(pattern, filename)
    if not match:
        print(f'⚠️ Skipping unrecognised filename format: {filename}')
        continue

    sample_id = match.group('sample_id')
    run_id = match.group('run_id')  # Optional, for logging
    instance_number = int(match.group('instance'))
    fasta_file_path = os.path.join(fasta_folder, filename)

    print(f'📤 Uploading {filename} → record: {sample_id}, run: {run_id}, instance: {instance_number}')

    # Prepare REDCap API payload
    data = {
        'token': API_TOKEN,
        'content': 'file',
        'action': 'import',
        'record': sample_id,
        'field': field_name,
        'repeat_instrument': 'sequencing',
        'repeat_instance': instance_number,
    }

    # Upload file
    with open(fasta_file_path, 'rb') as file:
        files = {'file': (filename, file, 'text/plain')}
        try:
            response = requests.post(REDCAP_API_URL, data=data, files=files)
        except requests.exceptions.RequestException as e:
            print(f'❌ Network error for {filename}: {e}')
            continue

    # Handle response
    if response.status_code == 200:
        uploaded_count += 1
        print(f'✅ Uploaded to record {sample_id}, instance {instance_number}')
    else:
        print(f'❌ Upload failed for {filename} (HTTP {response.status_code})')
        print(response.text)

# Final summary
print('\n🟢 Bulk upload complete.')
print(f'📊 Uploaded {uploaded_count} out of {total_files} FASTA files successfully.')
