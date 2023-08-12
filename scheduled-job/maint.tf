#TODO 
## Locals
locals {
  module-source = "../"
}
## Create a project 
module "project" {
  source          = "${local.module-source}project"
  billing_account = "123456-123456-123456"
  name            = "myproject"
  parent          = "folders/1234567890"
  prefix          = "foo"
  services = [
    "container.googleapis.com",
    "stackdriver.googleapis.com"
  ]
}
# tftest modules=1 resources=3 inventory=basic.yaml
## Create Service account
## Folders permissions ?
## Create Google cloud storage
## Create Docker artifact registry
## Create resource local_file Dockerfile
## Create resource local_file Copy Script
## Create null resource docker_build Build Image
## Create Google Cloud run JOB
## Create Google Cloud Scheduler - cron job