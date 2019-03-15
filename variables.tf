
variable "account" {
  description = "Code for account, defined in TFE (e.g apps)"
  default     = "wholesale"
}

variable "environment" {
  description = "Code for environment, defined in TFE (e.g uat)"
  default     = "dev"
}

variable "region" {
  description = "Code for environment, defined in TFE (e.g uat)"
  default     = "eu-west-1"
}

variable "role" {
  description = "Role used by SSM"
  default     = "null"
}

variable "s3_bucket" {
  description = "S3 bucket for loggin"
  default     = "aw-ssm-logs"
}

variable "mw_duration" {
  description = "Maintenance Window Duration"
  default     = "4"
}

variable "mw_cutoff" {
  description = "Maintenance Window Cutoff"
  default     = "1"
}

variable "mw_concurrency" {
  description = "Maintenance Window Concurrency Rate"
  default     = "100%"
}

variable "mw_error_rate" {
  description = "Maintenance Window Error Rate"
  default     = "100%"
}

variable "type" {
  description = "Maintenance Window Type (aws or vm)"
  default     = "vm"
}

variable "weeks" {
  description = "Number of weeks to schedule"
  default     = "1"
}

variable "day" {
  description = "Maintenance Window Day (mon-sun)"
  default     = "unnamed"
}

variable "hour" {
  description = "Maintenance Window Hour (00-23)"
  default     = "unnamed"
}

variable "powershell_package_file" {
  description = "File location to install powershell module"
  default     = "null"
}

variable "powershell_package_patameters" {
  description = "Parameters to install powershell module"
  default     = "/quiet /norestart"
}

variable "mi_list" {
  description = "List of Managed Instance Ids included in window"
  default     = ["mt-test","mt-test2"]
}


variable "powershell_package_file_before" {
  description = "File location to install powershell module"
  default     = "null"
}

variable "powershell_package_patameters_before" {
  description = "Parameters to install powershell module"
  default     = "/quiet /norestart"
}
