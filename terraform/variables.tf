variable "token" {
  type        = string
  description = "DigitalOcean API token"
}

variable "region" {
  type        = string
  default     = "tor1"
  description = "DigitalOcean region"
}

variable "agent_count" {
  type        = number
  default     = 2
  description = "Number of agents to create"
}

variable "cloudflare_api_token" {
  type        = string
  description = "The Cloudflare API token for Let's Encrypt DNS challenge and External DNS"
}
