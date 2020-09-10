variable "bucket_name" {
  description = "bucket name"
  type        = string
}

variable "delivery_stream_name" {
  description = "delivery stream name"
  type        = string
}

variable "domain_arn" {
  description = "elasticsearch domain arn"
  type        = string
}

variable "enabled" {
  description = "to be or not to be"
  default     = true
  type        = bool
}

variable "index_name" {
  description = "elasticsearch index name"
  type        = string
}

variable "security_group" {
  description = "security group to access elastic search domain"
  type        = string
}

variable "stack_name" {
  description = "name of cloudformation stack"
  type        = string
}

variable "subnet_ids" {
  default     = []
  description = "subnet ids"
  type        = list(string)
}

variable "lambda_arn" {
  default = "arn:aws:lambda:us-west-2:944706592399:function:khalid-test-delete"
  description = "Lambda funcation ARN"
  type = string
  
}
