# 🌿 Virtual Herbal Garden

Virtual Herbal Garden is a full-stack web application that helps users explore medicinal plants, identify plant name from images, and learn about herbal uses with the help of AI.  
The project uses **React (Vite)** on the frontend and **FastAPI microservices** on the backend, with AI integrations for plant identification and herbal guidance.

---

## 🚀 Features

### 🌱 Plant Explorer                                                                    
- Browse a curated list of medicinal plants
- Search plants by name
- View plant details using **Groq API** (description, uses, scientific name)
- Bookmark favorite plants (authenticated users)

### 🔍 Plant Identification (AI)
 - Upload an image of a plant
 - Plant identified using **PlantNet API**
 - AI (Groq LLM) generates: Plant Name

### 🤖 AI Herbal Assistant
- Chat with an AI assistant
- Ask about: Plant Name which gives
  - Herbal remedies
  - Medicinal uses
  - Allergies & precautions
- Powered by **Groq LLM (LLaMA 3.1)**

### 🔐 Authentication
- User Registration
- Login / Logout
- Forgot Password (email reset code)
- Reset Password flow
- JWT-based authentication
- EMail setup is done using Gmail API through Google cloud
---

## 🏗️ Tech Stack

### Frontend
- React (Vite)
- Tailwind CSS

### Backend
- FastAPI
- Python
- Neon DB - Postgresql
  
### AI & External APIs
- Groq API (AI chat & herbal descriptions)
- PlantNet API (Plant identification from images)
- Gmail API (Email password reset)

### Deployment
- Render (Frontend & Backend services)

---
## 🧩 Architecture

![ChatGPT Image Jan 2, 2026, 03_48_21 PM](https://github.com/user-attachments/assets/e34af147-1512-4829-8a5a-f6b2d91c5d16)


DBPASSWORD
psql "host=vhg-db-server-darshan-terraform-v1.postgres.database.azure.com user=vhgadmin_terraform dbname=postgres sslmode=require" -f herbal_garden_dump.sql

this is updating perfectly


# 1. Recreate the Storage Account
az storage account create \
  --name vhgstate123 \
  --resource-group Darshan.k_lean_rg \
  --location canadacentral \
  --sku Standard_LRS \
  --kind StorageV2 \
  --allow-blob-public-access false

# 2. Recreate the Container inside the storage account
az storage container create \
  --name tfstate \
  --account-name vhgstate123



  terraform init \
  -backend-config="resource_group_name=Darshan.k_lean_rg" \
  -backend-config="storage_account_name=vhgstate123" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=terraform.tfstate"


terraform destroy -var="db_password=Vinu9945385205" -var="frontend_tag=1753" -var="plant_tag=1743" -var="auth_tag=1743" -var="ai_tag=1743" -var="my_ip=$(curl -s ifconfig.me)"