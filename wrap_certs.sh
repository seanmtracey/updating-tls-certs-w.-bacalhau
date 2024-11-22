#!/bin/bash

# Ensure the target directory exists
sudo mkdir -p /etc/nginx/ssl

# Read the content of fullchain.pem
fullchain_content=$(cat fullchain.pem)

# Escape the content for use in the Python script (e.g., escape quotes and newlines if necessary)
escaped_fullchain=$(printf "%s" "$fullchain_content" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | awk '{printf "%s\\n", $0}')

# Read the content of privkey.pem
privkey_content=$(cat privkey.pem)

# Escape the content for use in the Python script
escaped_privkey=$(printf "%s" "$privkey_content" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | awk '{printf "%s\\n", $0}')

# Inject the content into the Python script
python_script=$(cat <<EOF
# Python script that writes TLS certificates to files
fullchain_var = """$escaped_fullchain"""
privkey_var = """$escaped_privkey"""

# Write the fullchain.pem content
with open("/etc/nginx/ssl/fullchain.pem", "w") as file:
    file.write(fullchain_var)

# Write the privkey.pem content
with open("/etc/nginx/ssl/privkey.pem", "w") as file:
    file.write(privkey_var)

print("TLS certificates written to /etc/nginx/ssl/")
EOF
)

# Base64 encode the entire Python script and output it
encoded_script=$(echo "$python_script" | base64)

# Output the base64 encoded script so it can be used as fulltext variable
echo "$encoded_script"
