variable "prefix"{
    description = "The prefix to use for the generated resources"
}

variable "resource-group"{
    description = "The resource group to use where Packer Image is located"
    default = "project1"
}

variable "location"{
    description = "The location to use for the generated resources"
    default = "uksouth"
}

variable "username"{
    description = "The username of the admin user"
    default = "admin123"
}

variable "password"{
    description = "The password of the admin user"
    default = "P@ssw0rd!"
}

variable "vms-count"{
    description = "No. of virtual machines to create"
    default = "2"
}
