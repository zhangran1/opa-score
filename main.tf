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
    "user:example@gmail.com"
  ]
}
