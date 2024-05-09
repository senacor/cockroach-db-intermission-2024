variable "region" {
  type = string
  default = "eu-central-1"
  description = "the id of the region, where 1 instance per available zone of the cockroach db should be deployed"
}

variable "number_of_available_zones" {
  type = number
  default = 1
  description = "the number of available zones, where 1 instance per available zone of the cockroach db should be deployed"
  validation {
    condition = var.number_of_available_zones > 0 && var.number_of_available_zones < 4
    error_message = "The number of the available zones ust be between 1 and 3"
  }
}

variable "ec2_instance_type" {
  type = string
  default = "t2.micro"
  description = "the ec2 instance type"
}