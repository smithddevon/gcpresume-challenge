provider "google" {
  project = "gcp-resume-challenge-083124"
  region  = "us-east4"
}

# Cloud Storage bucket for resume.json
resource "google_storage_bucket" "resume_bucket" {
  name     = "gcp-resume-bucket-083124"
  location = "us-east4"
}

# Cloud Function to retrieve resume data from Firestore (HTTP-triggered)
resource "google_cloudfunctions_function" "resume_function" {
  name                  = "get_resume"
  runtime               = "python39"
  entry_point           = "get_resume"  # Function to return data from Firestore

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
  entry_point           = "upload_to_firestore"  # Function to process the file and update Firestore

  source_archive_bucket = google_storage_bucket.resume_bucket.name
  source_archive_object = "source.zip"   # This will be updated by Cloud Build

  # Event trigger: listen for changes to objects in the storage bucket
  event_trigger {
    event_type = "google.storage.object.finalize"  # Triggers on file uploads/changes
    resource   = google_storage_bucket.resume_bucket.name
  }

  available_memory_mb = 256

  environment_variables = {
    FIRESTORE_PROJECT = "gcp-resume-challenge-083124"
  }

  service_account_email = "cloud-storage-service@gcp-resume-challenge-083124.iam.gserviceaccount.com"
}

# IAM policy to allow invocations of the Cloud Functions
resource "google_project_iam_member" "allow_unauthenticated" {
  project = "gcp-resume-challenge-083124"
  role    = "roles/cloudfunctions.invoker"
  member  = "allUsers"  # Allow unauthenticated access for the get_resume function
}

# Firestore setup (ensure Firestore is in native mode, manually set up)
# Uncomment if Firestore needs to be managed via Terraform
resource "google_firestore_database" "firestore_db" {
  name   = "(default)"
  project = "gcp-resume-challenge-083124"
  location_id = "us-east4"
}

# Cloud Build Trigger for automated deployment from GitHub
resource "google_cloudbuild_trigger" "github_trigger" {
  name = "gcp-resume-trigger"

  github {
    owner = "smithddevon"
    name  = "gcpresume-challenge"
    push {
      branch = "^master$"  # Adjust based on the branch you use
    }
  }

  filename = "cloudbuild.yaml"  # The file that defines the build steps

  service_account = "gcp-resume-challenge-083124@appspot.gserviceaccount.com"
}

# Output the Cloud Function URL for HTTP-triggered function
output "cloud_function_url" {
  description = "The HTTP endpoint for the deployed Cloud Function"
  value       = google_cloudfunctions_function.resume_function.https_trigger_url
}

