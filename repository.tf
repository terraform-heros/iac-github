resource "github_repository" "iac-github" {
  name = "iac-github"
  visibility = "public"
  description = "A Github repository to store and versioning our IaC code."
  allow_merge_commit = true
  gitignore_template = "Terraform"
  license_template = "mit"
  auto_init = true

}