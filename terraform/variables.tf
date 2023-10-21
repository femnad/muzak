variable "base_mount_point" {
  default = "/var/home/core/muzak"
}

variable "music_mount_point" {
  default = "/var/home/core/muzak/music"
}

variable "navidrome_mount_point" {
  default = "/var/home/core/muzak/navidrome"
}

variable "gcsfuse_tag" {
  default = "0.1.9"
}

variable "navidrome_tag" {
  default = "0.1.1"
}

variable "ignition_file" {
  default = "muzak.ign"
}

variable "managed_connection" {
  default = true
}

variable "region" {
  default = "europe-west2"
}

variable "zone" {
  default = "europe-west2-b"
}
