provider "google" {
  project = "gcp-resume-challenge-083124"
  region  = "us-east4"
}

# Cloud Storage bucket for resume.json
resource "google_storage_bucket" "resume_bucket" {
  name     = "gcp-resume-bucket-083124"    # Your existing bucket with resume.json
  location = "us-east4"
}

# Cloud Function to handle resume retrieval
resource "google_cloudfunctions_function" "resume_function" {
  name                  = "get_resume"
  runtime               = "python39"
  entry_point           = "get_resume"
  
  # Cloud Build will handle deployment, so no need for source_archive_bucket/object
  source_archive_bucket = google_storage_bucket.resume_bucket.name
  source_archive_object = "source_zip"   # This will be replaced by Cloud Build
  
  trigger_http          = true
  available_memory_mb   = 256

  environment_variables = {
    FIRESTORE_PROJECT = "gcp-resume-challenge-083124"
  }

  service_account_email = "gcp-resume-challenge-083124@appspot.gserviceaccount.com"
}

# IAM policy to allow invocations of the Cloud Function
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
    owner = "smithddevon"  # Replace with your GitHub username
    name  = "gcp-resume-challenge"        # Replace with your GitHub repo name
    push {
      branch = "^master$"  # Adjust if you're using a different branch
    }
  }

  # The file that defines the build steps
  filename = "cloudbuild.yaml"

  # Include the service account for Cloud Build if required
  service_account = "gcp-resume-challenge-083124@appspot.gserviceaccount.com"
}