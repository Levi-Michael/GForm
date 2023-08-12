#TODO 
## Create a project 
module "project" {
  source          = "git::github.com/GoogleCloudPlatform/cloud-foundation-fabric/modules/project"
  billing_account = "123456-123456-123456"
  name            = "project-00"
  prefix          = "scheduled-job"
  # If you useing as an organization you need to provide a parent folder for the project.
  # parent          = "folders/1234567890"
  services = [
    "cloudapis.googleapis.com"
  ]
}

## Create Service account
## Folders permissions ?
## Create Google cloud storage
## Create Docker artifact registry
## Create resource local_file Dockerfile
## Create resource local_file Copy Script
## Create null resource docker_build Build Image
## Create Google Cloud run JOB
## Create Google Cloud Scheduler - cron job