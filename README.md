# Open Policy Agent Evaluate Infrastructure Score

This repo contains a library of constraint templates and sample constraints.


### Quick start commands

#### Configure Environment Variable
Set Environment variable, SOURCE_CODE_REPOSITORY for the name of cloud source repository

```bash
export SOURCE_CODE_REPOSITORY=opa-score-repository
```

#### Step by Step Guide

1. Create a repository in Cloud Source Repositories in the project of your choice in Google Cloud Platform.
     ```bash
     gcloud source repos create $SOURCE_CODE_REPOSITORY
     ```

2. Clone the policy library.
    ```bash
    git clone https://github.com/GoogleCloudPlatform/policy-library.git
    ```

3. Add the library to your existing repository to your source code repository.
    ```bash
    cd policy-library
    git remote add google $SOURCE_CODE_REPOSITORY
    git push - all google
    ```
   
4. Create the following Terraform main.tf file in the current directory(policy-library). This is not the best folder structure.
    ```bash
    terraform {
      required_providers {
        google = {
          source = "hashicorp/google"
          version = "~> 3.84"
        }
      }
    }
    
    resource "google_project_iam_binding" "sample_iam_binding" {
      project = "PROJECT_ID"
      role    = "roles/viewer"
    
      members = [
        "user:EMAIL_ADDRESS"
      ]
    }
    ```
    Replace the following:

   - PROJECT_ID: your project ID.
   - EMAIL_ADDRESS: a sample email address. This can be any valid email address. For example, user@example.com.

    ```bash
    sed -i 's/PROJECT_ID/opa-score-project/g' main.tf
    sed -i 's/EMAIL_ADDRESS/user@example.com/g' main.tf
    ```


5. Initialize Terraform and generate a Terraform plan using the following:

    ```bash
    terraform init
    ```
   
6. Export the Terraform plan, if asked, click Authorize when prompted:

    ```bash
    terraform plan -out=test.tfplan
    ```

7. Convert the Terraform plan to JSON:

    ```bash
    terraform plan -out=test.tfplan
    ```
   
8. Create a score directory

    ```bash
    mkdir score
    cd score
    ```

9. Create the following gcp_check_score_constraint.rego in the score directory

     ```bash
     # Copyright 2023 Google LLC
     #
     # Licensed under the Apache License, Version 2.0 (the "License");
     # you may not use this file except in compliance with the License.
     # You may obtain a copy of the License at
     #
     #      http://www.apache.org/licenses/LICENSE-2.0
     #
     # Unless required by applicable law or agreed to in writing, software
     # distributed under the License is distributed on an "AS IS" BASIS,
     # WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
     # See the License for the specific language governing permissions and
     # limitations under the License.
     #
    
     package templates.gcp.GCPCheckScoreConstraintV1
    
     import input as tfplan
    
    
      # acceptable score-policy for automated authorization
      blast_radius := 30
    
      # weights assigned for each operation on each resource-type
      #weights := params.weights
      weights := {
       "google_compute_instance_template": {"delete": 100, "create": 10, "modify": 1},
       "google_compute_region_backend_service": {"delete": 100, "create": 10, "modify": 1},
       "google_compute_health_check": {"delete": 100, "create": 10, "modify": 1},
       "google_compute_region_autoscaler": {"delete": 100, "create": 10, "modify": 1},
       "google_compute_region_instance_group_manager": {"delete": 100, "create": 10, "modify": 1},
       "google_compute_address": {"delete": 100, "create": 10, "modify": 1},
       "google_compute_forwarding_rule": {"delete": 100, "create": 10, "modify": 1},
       "google_compute_region_url_map": {"delete": 100, "create": 10, "modify": 1},
       "google_compute_region_target_http_proxy": {"delete": 100, "create": 10, "modify": 1},
       "google_compute_region_target_https_proxy": {"delete": 100, "create": 10, "modify": 1},
       "google_service_account": {"delete": 100, "create": 10, "modify": 1},
       "google_service_account_iam_binding": {"delete": 100, "create": 10, "modify": 1},
       "google_project_iam_binding": {"delete": 100, "create": 10, "modify": 1},
       "google_project_iam_member": {"delete": 100, "create": 10, "modify": 1},
       "google_compute_project_metadata_item":  {"delete": 100, "create": 10, "modify": 1},
       "google_compute_instance":  {"delete": 100, "create": 10, "modify": 1},
      }
    
      # Consider exactly these resource types in calculations
      resource_types := {"google_compute_instance",
                        "google_compute_project_metadata_item",
                        "google_project_iam_member",
                        "google_project_iam_binding",
                        "google_service_account_iam_binding",
                        "google_service_account",
                        "google_compute_instance_template",
                        "google_compute_region_backend_service",
                        "google_compute_health_check",
                        "google_compute_region_autoscaler",
                        "google_compute_region_instance_group_manager",
                        "google_compute_address",
                        "google_compute_forwarding_rule",
                        "google_compute_region_url_map",
                        "google_compute_region_target_http_proxy",
                        "google_compute_region_targets_http_proxy"}
    
     # Compute the score-policy for a Terraform plan as the weighted sum of deletions, creations, modifications
     score := s {
      all := [x |
       some resource_type
       crud := weights[resource_type]
       del := crud.delete * num_deletes[resource_type]
       new := crud.create * num_creates[resource_type]
       mod := crud.modify * num_modifies[resource_type]
       x := (del + new) + mod
      ]
    
      s := sum(all)
     }
    
    
     #Whether there is any change to IAM
     touches_iam {
      all := resources.gcp_iam
      count(all) > 0
     }
    
     ####################
     # Terraform Library
     ####################
    
     # list of all resources of a given type
     resources[resource_type] := all {
      some resource_type
      resource_types[resource_type]
      all := [name |
       name := tfplan.resource_changes[_]
       name.type == resource_type
      ]
     }
    
     # number of creations of resources of a given type
     num_creates[resource_type] := num {
      some resource_type
      resource_types[resource_type]
      all := resources[resource_type]
      creates := [res | res := all[_]; res.change.actions[_] == "create"]
      num := count(creates)
     }
    
     # number of deletions of resources of a given type
     num_deletes[resource_type] := num {
      some resource_type
      resource_types[resource_type]
      all := resources[resource_type]
      deletions := [res | res := all[_]; res.change.actions[_] == "delete"]
      num := count(deletions)
     }
    
     # number of modifications to resources of a given type
     num_modifies[resource_type] := num {
      some resource_type
      resource_types[resource_type]
      all := resources[resource_type]
      modifies := [res | res := all[_]; res.change.actions[_] == "update"]
      num := count(modifies)
     }
     ```

10. Below is the general instruction to calculate the score.

   ```bash
   opa exec --decision PACKAGE_NAME/EVALUATION_VARIABLE --bundle  PERFORMANCE_SCORE_POLICY_FOLDER_PATH TERRAFORM_PLAN_JSON_FILE_PATH
   ```
   Where,
   
   PACKAGE_NAME/EVALUATION_VARIABLE refers to the variable you would like to evaluate.
   
   PERFORMANCE_SCORE_POLICY_FOLDER_PATH stores the policy used to calculate the performance score.
   
   TERRAFORM_PLAN_JSON_FILE_PATH refers to the terraform plan json file path.
   
   Following script is the sample bash script that could be deployed in the pipeline. Replace the TERRAFORM_PLAN_JSON_FILE_PATH to your own file path.

   ```bash
   opa exec --decision templates/gcp/GCPCheckScoreConstraintV1/score --bundle score/ ./tfplan.json 
   ```

11. You may get the following sampler response from previous. Filter the result value from the deployment pipeline, you may choose to pass or fail the deployment.

   ```bash
   {
     "result": [
       {
         "path": "./tfplan.json",
         "result": 10
       }
     ]
   }
   ```

### Medium article references

You may find the step by step instruction in [Open Policy Agent Evaluate Infrastructure Score](https://zhangran1.medium.com/open-policy-agent-evaluate-infrastructure-score-8cdf13c7cc46).

