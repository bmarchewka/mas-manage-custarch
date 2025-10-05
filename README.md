# mas-manage-custarch
Maximo Application Suite - Manage - Customisation Archive

## 📦 Manage Customization Archive Automation

This project automates the packaging and deployment of customization archives for IBM MAS Manage using Bitbucket Pipelines and OpenShift. It includes a CD pipeline configuration and a shell script to zip, upload, and update customization archive references in an OpenShift (ManageWorkspace).

---

### 🧰 Components

#### 1. `bitbucket-pipelines.yml`
Defines a custom Bitbucket pipeline (`manage-publish-dev`) that:
- Installs required CLI tools: `yq`, `oc` (OpenShift CLI), and `awscli`.
- Executes the `manage-cust-archive.sh` script with environment variables.
- Publishes artifacts to the `build/` directory.

#### 2. `manage-cust-archive.sh`
A Bash script that:
- Zips the contents of the `manage/` folder into a timestamped archive.
- Uploads the archive to a specified AWS S3 bucket.
- Verifies the upload by checking the HTTP status of the file URL.
- Logs into an OpenShift cluster and updates the `customizationArchiveUrl` in the `ManageWorkspace` definition.

---

### 🚀 Usage

#### Pipeline Trigger
Run the custom pipeline manually in Bitbucket using:

```yaml
pipelines:
  custom:
    manage-publish-dev:
      - step:
          <<: *publish-step
          deployment: DEV
```

#### Script Execution
The script expects the following arguments:

```bash
./manage-cust-archive.sh <ocp_username> <ocp_password> <ocp_server_url> <aws_bucket> <aws_bucket_url>
```

Example:

```bash
./manage-cust-archive.sh admin password https://ocp.example.com s3://mybucket/customer/masdemo https://mybucket.s3.amazonaws.com/customer/masdemo/
```

---

### 🔐 Requirements

- OpenShift CLI (`oc`)
- AWS CLI (`aws`)
- `yq` for YAML manipulation
- Git (used to retrieve the last commit hash)
- Access to an OpenShift cluster and AWS S3 bucket

---

### 📁 Output

- Archive uploaded to S3 and referenced updated in the MAS Manage workspace
