#!/usr/bin/env python3
"""
Patch to fix basicsr.utils.download_util.load_file_from_url import issue.
This adds the missing load_file_from_url function to basicsr.
"""

import sys
import os

# Add the basicsr package to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# First, let's check if basicsr is importable
try:
    import basicsr.utils.download_util as download_util
    print("basicsr.utils.download_util imported successfully")
    
    # Check if load_file_from_url exists
    if hasattr(download_util, 'load_file_from_url'):
        print("load_file_from_url already exists in basicsr.utils.download_util")
    else:
        print("load_file_from_url not found in basicsr.utils.download_util, adding it...")
        
        # Add the missing function
        import requests
        import hashlib
        from tqdm import tqdm
        import os
        
        def load_file_from_url(url, model_dir, progress=True, file_name=None):
            """Download a file from url into model_dir.
            
            Args:
                url (str): URL to download from.
                model_dir (str): Directory to download to.
                progress (bool): Whether to show progress bar.
                file_name (str): Name of the file to save as.
                
            Returns:
                str: Path to the downloaded file.
            """
            os.makedirs(model_dir, exist_ok=True)
            
            if file_name is None:
                # Extract filename from URL
                file_name = os.path.basename(url)
                # Remove query parameters
                file_name = file_name.split('?')[0]
                # If no filename in URL, use hash
                if not file_name or '.' not in file_name:
                    file_name = hashlib.md5(url.encode()).hexdigest() + '.pth'
            
            file_path = os.path.join(model_dir, file_name)
            
            # Skip if file already exists
            if os.path.exists(file_path):
                return file_path
            
            # Download file
            response = requests.get(url, stream=True)
            response.raise_for_status()
            
            total_size = int(response.headers.get('content-length', 0))
            
            with open(file_path, 'wb') as f:
                if progress and total_size > 0:
                    with tqdm(total=total_size, unit='B', unit_scale=True, desc=file_name) as pbar:
                        for chunk in response.iter_content(chunk_size=8192):
                            if chunk:
                                f.write(chunk)
                                pbar.update(len(chunk))
                else:
                    for chunk in response.iter_content(chunk_size=8192):
                        if chunk:
                            f.write(chunk)
            
            return file_path
        
        # Add the function to the module
        download_util.load_file_from_url = load_file_from_url
        
        # Also add it to __all__ if it exists
        if hasattr(download_util, '__all__'):
            download_util.__all__.append('load_file_from_url')
        
        print("Successfully added load_file_from_url to basicsr.utils.download_util")
        
except ImportError as e:
    print(f"Error importing basicsr: {e}")
    sys.exit(1)
except Exception as e:
    print(f"Error: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)

print("Patch applied successfully!")