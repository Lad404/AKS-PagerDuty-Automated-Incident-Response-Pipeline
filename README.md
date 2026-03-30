# 🚀 AKS + PagerDuty: Automated Incident Response Pipeline

This repository contains **Infrastructure as Code (IaC)** and configuration to build a mission-critical observability pipeline. It automates the detection of Kubernetes Pod failures and triggers real-time alerts via PagerDuty.

## 📌 Project Overview
In a cloud-native environment, manual monitoring is a bottleneck. This project solves that by connecting **Azure Kubernetes Service (AKS)** health metrics to **PagerDuty** using **Azure Monitor** and **Terraform**.

### The Flow:
1. **AKS** runs a containerized application.
2. **Log Analytics** ingests pod status data every minute.
3. **Azure Monitor** runs a KQL query to find any pod where `Status != Running`.
4. **Action Group** sends a Webhook payload to **PagerDuty**.
5. **PagerDuty** alerts the On-Call Engineer via SMS, Email, or Phone Call.

---

## 🛠️ Tech Stack
* **Cloud:** Microsoft Azure
* **Orchestration:** Azure Kubernetes Service (AKS)
* **IaC:** Terraform
* **Monitoring:** Azure Log Analytics & Kusto Query Language (KQL)
* **Incident Management:** PagerDuty

---

## 🚀 Deployment Steps

### 1. PagerDuty Setup
* Create a New Service: `AKS-Cluster-Health`.
* Select **Microsoft Azure** as the integration.
* Copy the generated **Integration URL**.
  <img width="850" height="505" alt="image" src="https://github.com/user-attachments/assets/cd8d8c31-670a-4f58-9e77-34b6a84fe5c4" />

  <img width="853" height="506" alt="image" src="https://github.com/user-attachments/assets/fdce7817-0675-4666-ae1c-6b9690cc0ded" />

  <img width="857" height="509" alt="image" src="https://github.com/user-attachments/assets/cc35da30-29fa-468c-a7be-8864c59f947a" />


### 2. Infrastructure Deployment
* Clone this repo.
* Update `aks_monitoring.tf` with your PagerDuty Webhook URL and your Azure region.
* Run the following commands in Azure Cloud Shell:
```bash
terraform init
terraform plan
terraform apply -auto-approve
```
Connect to your AKS cluster using the Connect option(commands given to connect using Bash):

<img width="1920" height="1140" alt="image" src="https://github.com/user-attachments/assets/8d6eefce-6388-4025-8782-ef88a492ed2a" />



### 3. Verification (Chaos Testing)
Simulate a failure by deploying a pod that is designed to crash:
```bash
kubectl run broken-pod --image=busybox --restart=Never -- /bin/sh -c "exit 1"
```
<img width="865" height="514" alt="image" src="https://github.com/user-attachments/assets/e8b04495-7fe9-4444-bd8c-508692df3a53" />

# Check the logs on LAW:
<img width="825" height="464" alt="image" src="https://github.com/user-attachments/assets/d3886b3e-84a2-4605-8a53-18a8225268da" />

# Check the Alert:
<img width="832" height="494" alt="image" src="https://github.com/user-attachments/assets/14814e7c-8219-4530-a676-e7d9de56fb4d" />


*Check your PagerDuty dashboard after 5 minutes to see the triggered incident.*

<img width="835" height="438" alt="image" src="https://github.com/user-attachments/assets/9a7bbb07-cff0-4c6a-b7f9-598f497f672a" />

<img width="874" height="519" alt="image" src="https://github.com/user-attachments/assets/ab20934d-8230-4202-b357-b51364b803ad" />

---

## 🔮 Future Enhancements (Production Scenarios)

To move this from a demo to a **Production-Grade** SRE platform, the following enhancements are recommended:

* **Self-Healing with Azure Functions:** Integrate an Azure Function into the Action Group that automatically restarts the failed pod or clears the cache before a human is even paged.
* **Service Mesh Integration:** Use **Istio** or **Linkerd** to monitor 5xx error rates and latency between microservices, sending alerts if the "Golden Signals" of SRE are breached.
* **Dynamic Escalation:** Configure PagerDuty to route alerts to different teams based on the Kubernetes **Namespace** (e.g., Database team vs. Frontend team).
* **Terraform State Management:** Move the `.tfstate` file to an **Azure Blob Storage** backend with State Locking to allow multiple DevOps engineers to work on the infrastructure simultaneously.
* **Discord/Slack Notifications:** Add multiple receivers to the Azure Action Group to provide "ChatOps" visibility alongside the PagerDuty alert.

---
