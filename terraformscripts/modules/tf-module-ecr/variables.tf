variable "ecr_repos" {
  type        = list
  description = "ECR repositories names"
}

variable "create_ecr_full_policy" {
  description = "If set to true, it will create automatically a Policy for the ECR"
  default     = false
}

variable "enable_lifecycle_policy" {
  description = "If set to true it will create a lifecycle policy for ECR repositories. You will need to see also `number_of_images` and `image_tag_prefix`"
  default     = false
}

variable "number_of_images" {
  description = "Set how much image versions would you like to keep. Default is `30`"
  default     = 30
}

variable "image_tag_prefix" {
  description = "Choose a specific tag prefix for which you want to apply lifecycle policy. Default is `V`"
  default     = "V"
}

variable "create_ecr_pull_policy" {
  description = "If set to true, it will create automatically a Policy to pull from other accounts"
  default     = false
}

variable "accounts_ids" {
  description = "Accounts IDs that want to have access in ECR"
  type        = list
  default     = []
}
