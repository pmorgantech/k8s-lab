terraform {
  required_providers {
    libvirt = {
      source  = "dockstudios/libvirt"
      version = "1.2.1"
    }

    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}
