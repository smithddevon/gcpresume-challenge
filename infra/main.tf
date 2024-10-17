provider "google" {
  project = "gcp-resume-challenge-083124"
  region  = "us-east4"
}

# Cloud Storage bucket for resume.json
resource "google_storage_bucket" "resume_bucket" {
  name     = "gcp-resume-bucket-083124"  # Your bucket for storing resume.json
  location = "us-east4"
}

# Cloud Function to retrieve resume data from Firestore (HTTP-triggered)
resource "google_cloudfunctions_function" "resume_function" {
  name                  = "get_resume"
  runtime               = "python39"
  entry_point           = "get_resume"  # This function returns data from Firestore

  # Cloud Build will handle deployment
  source_archive_bucket = google_storage_bucket.resume_bucket.name
  source_archive_object = "source.zip"   # This will be updated by Cloud Build

  trigger_http          = true
  available_memory_mb   = 256

  environment_variables = {
    FIRESTORE_PROJECT = "gcp-resume-challenge-083124"
  }

  service_account_email = "gcp-resume-challenge-083124@appspot.gserviceaccount.com"
}

# Cloud Function to update Firestore when resume.json is modified in Cloud Storage
resource "google_cloudfunctions_function" "update_firestore_function" {
  name                  = "update_resume_firestore"
  runtime               = "python39"
  entry_point           = "upload_to_firestore"  # Python function that processes the file

  # Cloud Build will handle deployment
  source_archive_bucket = google_storage_bucket.resume_bucket.name
  source_archive_object = "source.zip"   # This will be updated by Cloud Build

  # Event trigger: listen for changes to objects in the storage bucket
  event_trigger {
    event_type = "google.storage.object.finalize"  # Triggers on file uploads/changes
    resource   = google_storage_bucket.resume_bucket.name
    failure_policy {
      retry = true  # Optional: retry on failure
    }
  }

  available_memory_mb = 256

  environment_variables = {
    FIRESTORE_PROJECT = "gcp-resume-challenge-083124"
  }

  service_account_email = "gcp-resume-challenge-083124@appspot.gserviceaccount.com"
}

# IAM policy to allow invocations of the Cloud Functions
resource "google_project_iam_policy" "policy" {
  project = "gcp-resume-challenge-083124"

  policy_data = jsonencode({
    "bindings" = [
      {
        "role"    = "roles/cloudfunctions.invoker",
        "members" = [
          "allUsers"
        ]
      }
    ]
  })
}

# Cloud Build Trigger for automated deployment from GitHub
resource "google_cloudbuild_trigger" "github_trigger" {
  name = "gcp-resume-trigger"

  # GitHub repository details
  github {
    owner = "smithddevon"
    name  = "gcpresume-challenge"
    push {
      branch = "^master$"  # Adjust based on the branch you use
    }
  }

  # The file that defines the build steps
  filename = "cloudbuild.yaml"

  # Include the service account for Cloud Build
  service_account = "gcp-resume-challenge-083124@appspot.gserviceaccount.com"
}

# Output the Cloud Function URL for HTTP-triggered function
output "cloud_function_url" {
  description = "The HTTP endpoint for the deployed Cloud Function"
  value       = google_cloudfunctions_function.resume_function.https_trigger_url
}
