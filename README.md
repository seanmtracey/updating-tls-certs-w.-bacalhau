# **Let's Encrypt Certificate Deployments with Bacalhau**

This repository contains scripts and configuration files for simplifying TLS certificate management and deployment across a distributed infrastructure using Let’s Encrypt and Bacalhau. The setup leverages Ubuntu servers, NGINX for web serving, and Bacalhau for orchestrating certificate deployment.

---

## **Repository Contents**

### **`job.yaml`**
- **Purpose**: Defines a Bacalhau job for deploying TLS certificates to multiple servers.
- **Details**:
  - Specifies the use of Bacalhau's Python runner to execute the certificate deployment script.
  - Maps `/etc/nginx/ssl` for reading and writing certificates on each compute node.
  - Includes environment variables for passing the Python script as a base64-encoded string and enabling debugging.

### **`userdata-compute.sh`**
- **Purpose**: Configures a compute node for Bacalhau and sets up NGINX with TLS support.
- **Key Features**:
  - Installs and configures NGINX and Docker.
  - Installs Bacalhau and sets it up as a compute node connected to an orchestrator.
  - Configures a directory watcher (`cert-watch.sh`) to monitor `/etc/nginx/ssl` for changes and reload NGINX automatically when certificates are updated.
  - Registers a systemd service for the watcher to start on boot and ensures certificates are always up-to-date.

### **`userdata-orchestrator.sh`**
- **Purpose**: Configures an orchestrator node for Bacalhau.
- **Key Features**:
  - Installs Docker and Bacalhau.
  - Sets up Bacalhau as an orchestrator node with a WebUI available at port `8483`.
  - Registers a systemd service to start the orchestrator on boot.

### **`wrap_certs.sh`**
- **Purpose**: Prepares TLS certificates for deployment to servers.
- **Key Features**:
  - Reads `fullchain.pem` and `privkey.pem` certificates from a Let's Encrypt directory.
  - Escapes the contents for use in a Python script.
  - Generates a Python script to write the certificates to `/etc/nginx/ssl` on target servers.
  - Outputs the Python script as a base64-encoded string, which is used as input for Bacalhau jobs.

---