# 🔐 GitHub → Azure Federated Identity via OIDC with Flexible Federated Identity Credentials

### A secure automation setup using GitHub Actions, Azure AD, and Ansible — supporting all branches via wildcard claims using the new Flexible Federated Identity (FIC) model.

---

## Background

GitHub Actions workflows are often designed to access a cloud provider (such as AWS, Azure, GCP, or HashiCorp Vault) in order to deploy software or use the cloud's services. Before the workflow can access these resources, it will supply credentials, such as a password or token, to the cloud provider. These credentials are usually stored as a secret in GitHub, and the workflow presents this secret to the cloud provider every time it runs.

However, using hardcoded secrets requires you to create credentials in the cloud provider and then duplicate them in GitHub as a secret.

With OpenID Connect (OIDC), you can take a different approach by configuring your workflow to request a short-lived access token directly from the cloud provider. Your cloud provider also needs to support OIDC on their end, and you must configure a trust relationship that controls which workflows are able to request the access tokens. Providers that currently support OIDC include Amazon Web Services, Azure, Google Cloud Platform, and HashiCorp Vault, among others.

### [Benefits of using OIDC](https://docs.github.com/en/actions/security-for-github-actions/security-hardening-your-deployments/about-security-hardening-with-openid-connect#benefits-of-using-oidc)

By updating your workflows to use OIDC tokens, you can adopt the following good security practices:

- **No cloud secrets:** You won't need to duplicate your
cloud credentials as long-lived GitHub secrets. Instead, you can
configure the OIDC trust on your cloud provider, and then update your
workflows to request a short-lived access token from the cloud provider
through OIDC.
- **Authentication and authorization management:** You
have more granular control over how workflows can use credentials, using your cloud provider's authentication (authN) and authorization (authZ)
tools to control access to cloud resources.
- **Rotating credentials:** With OIDC, your cloud
provider issues a short-lived access token that is only valid for a
single job, and then automatically expires.

This architecture showcases how GitHub Actions can securely authenticate with cloud providers — especially Azure — using OIDC and **Flexible Federated Identity Credentials (FIC)**.

## 🧭 Architecture Overview

![OIDC Federated Identity Architecture](/images/OpenID%20Connect%20-%20GitHub%20Actions%20workflow.png "OIDC Federated Identity")

<figure>
<img src="/images/OpenID Connect - GitHub Actions workflow.png" alt=""/>
<figure-caption>Figure 1. OIDC Federated Identity Architecture Flow</figure-caption>
</figure>

---

## **OpenID Connect (OIDC) Auth Flow Breakdown**

1. **Cloud Provider Setup**
    - Define **OIDC Trust** with GitHub's OIDC Provider
    - Create Roles or Service Principals
    - Assign least-privilege access (e.g., Contributor role)
2. **GitHub Workflow Execution**
    - When a workflow job starts, GitHub generates an **OIDC Token**
    - Token contains secure claims like:
        - `sub`: Subject (repo, branch, environment)
        - `aud`: Audience
        - `iss`: Issuer
3. **Token Exchange**
    - GitHub workflow requests access token by presenting the JWT to the cloud provider.
    - Cloud provider **verifies claims**, then issues a **short-lived access token** (AuthZ)
4. **Cloud Access**
    - Access token is scoped, time-bound, and secure.
    - Used by job steps like Terraform, Azure CLI, etc.

## 🎯 Objective

Enable GitHub Actions from **any branch** to securely authenticate to **Azure** via **OIDC**, using short-lived tokens — without static credentials or multiple federated identity entries.

---

## 🚀 Key Features

- ✅ Federated identity using `claimsMatchingExpression`
- ✅ No static secrets — uses GitHub OIDC
- ✅ Secrets encrypted using GitHub repo public key & Libsodium
- ✅ Setup and configuration via Ansible and Bash

---

## 📦 Project Structure

```bash
ansible_playbook/
├── scripts/
│ └── encrypt_secrets.py
├── run_federation_setup.sh # 🔧 Bash wrapper
├── requirements-azure.txt # 🧩 Azure SDK requirements
├── ansible_playbook_azure_gh.yml # 🎯 Main playbook
.github/
└── workflows/
└── test-azure-setup.yml # ✅ GitHub Actions test
```

---

## ✅ Prerequisites

### 🔹 Azure CLI + Login
### 🔹Python 3

```bash
az login
az account set --subscription "<your-subscription-id>"
```

## 🛠️ Running the Federation Setup Script

1. Make the federation setup script executable:
```bash
chmod +x ansible_playbook/run_federation_setup.sh
```
2. Run the script with full path (recommended):
```bash
./ansible_playbook/run_federation_setup.sh
```
📌 This script:

-  Creates an Azure AD Application

- Registers a Service Principal

- Assigns RBAC role

- Creates Flexible Federated Identity Credential using az rest

- Encrypts secrets and pushes to GitHub

🔐 Example: Flexible FIC Setup
```json
{
  "name": "github-flex-fic",
  "issuer": "https://token.actions.githubusercontent.com",
  "audiences": [ "api://AzureADTokenExchange" ],
  "claimsMatchingExpression": {
    "value": "claims['sub'] matches 'repo:ORG/REPO:ref:refs/heads/*'",
    "languageVersion": 1
  }
}
```
## 🔐 Secrets Encryption (Libsodium)
```python
from nacl import encoding, public
import base64

key = public.PublicKey(public_key.encode("utf-8"), encoding.Base64Encoder())
sealed_box = public.SealedBox(key)
encrypted = sealed_box.encrypt(secret.encode("utf-8"))
print(base64.b64encode(encrypted).decode("utf-8"))
```

## ✅ Test GitHub Actions Setup
.github/workflows/test-azure-setup.yml
```yaml
name: Verify Azure Setup

on:
  push:
    branches:
      - feature/**

jobs:
  validate-azure-login:
    runs-on: ubuntu-latest
    environment: azure
    steps:
      - uses: actions/checkout@v3

      - name: Azure Login
        uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
          audience: api://AzureADTokenExchange
          auth-type: SERVICE_PRINCIPAL

      - name: Show Azure Identity
        run: az account show
```

## 🧠 References
- [Azure Workload Identity - Issue #373](https://github.com/Azure/azure-workload-identity/issues/373#issuecomment-2521617494)

- [Microsoft Docs - Workload Federation](https://learn.microsoft.com/entra/workload-id/workload-identity-federation-create-trust)
- [Microsoft Docs - Github Connect from Azure secret](https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure-secret)
- [Microsoft Docs - Flexible Federated Identity Credentials (FIC)](https://learn.microsoft.com/en-us/rest/api/managedidentity/federated-identity-credentials/create-or-update?view=rest-managedidentity-2025-01-31-preview&tabs=HTTP#claimsmatchingexpression)