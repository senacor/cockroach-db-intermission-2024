variable "name" {
  type = string
}

variable "location" {
  type = string
}

variable "address_space" {
  type = string
}

variable "nodes" {
  type = list(object({
    name     = string
    region   = string
    zone     = string
    provider = string
  }))
}
