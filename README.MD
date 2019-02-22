# New Relic Candidate Lab Deploy
## Terraform on Azure

### Prerequisites

1. [Terraform](https://www.terraform.io/downloads.html) installed
2. [Azure command line](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest) (i.e. `az`) installed
3. [Logged into your azure account](https://docs.microsoft.com/en-us/cli/azure/authenticate-azure-cli?view=azure-cli-latest) in the cli:  `az login`
4. Valid default SSH key pair (i.e. `id_rsa` and `id_rsa.pub`) located in your user ssh directory (i.e. `~/.ssh`)



### Setup

1. Clone this directory into a new folder for each candidate: `git clone https://github.com/davemurphysf/NewRelicCandidateLabDeploy.git <CandidateName>`
2. Go into the directory `cd <CandidateName>`
3. Get your Azure Subscription `id` and `tenantId` via: `az account show`
```
@Azure:~$ az account show
{
  "environmentName": "AzureCloud",
  "id": "9ffe9512-f4a2-42dd-1230-518aec34be21",
  "isDefault": true,
  "name": "Beyond Team Sandbox",
  "registeredProviders": [],
  "state": "Enabled",
  "tenantId": "ac6692da-1231-422f-22a8-9eed6dbe83f1",
  "user": {
    "name": "agomez@datanerd.us",
    "type": "user"
}
```
4. Create a file titled `terraform.tfvars` with the following contents
```
subscription_id = "<Azure Subscription ID>"
tenant_id = "<Azure Tenant ID"
expiration = "YYYY-MM-DD"  //Date you want the candidates user account on the VM to expire
password = "<Password for candidate>"  // i.e. AVeryLongPassword
candidate_name = "<Name>" //No spaces allowed; used to namespace Azure resources from other candidates
```
5. Run `terraform init` to install the Terraform Azure provider
6. Run `terraform plan -out tf.plan`.  
7. Once the plan is created, run `terraform apply tf.plan` to apply the scripts.  It should take 5-10 minutes to create the entire environment
8. Once complete, there should be 3 Outputs listed for the candidate to access the VM
```
app_dns = <prefix>.westus.cloudapp.azure.com
vm_password = <password>
vm_username = <username>
```
9. The candiate can then log into the VM using `ssh <vm_username>@<app_dns>`
10. You can login yourself under the default admin account (`myadmin`) using your existing SSH key: `ssh myadmin@<app_dns>`
11. To destroy the environment after the lab is complete, use `terraform destroy -auto-approve`
