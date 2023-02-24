#
# Copyright 2022 Google LLC
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