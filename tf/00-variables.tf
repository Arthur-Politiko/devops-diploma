#**********************************************#
variable "project_name" {
  description = "Project name"
  type        = string
  default     = "devops-diploma"
}

variable "ansible_config_path" {
  description = "Path to the Ansible configuration file"
  type        = string
  default     = "../ansible/ansible.cfg"
}

variable "ansible_inventory_path" {
  description = "Path to the Ansible inventory file"
  type        = string
  default     = "../ansible/inventory.ini"
}

variable "ansible_inventory_template_path" {
  description = "Path to the Ansible inventory file"
  type        = string
  default     = "templates/inventory.tpl"
}

#**********************************************#
###cloud vars
variable "token" {
  description = "IAM token for provider authentication"
  type        = string
  default     = null
  sensitive   = true
  nullable    = true
}

variable "sa_key_file" {
  description = "Path SA key file"
  type        = string
  default     = "../vault/diploma-sa-key.json"
  nullable    = true
}

variable "organization_id" {
  description = "Organization ID for Yandex.Cloud"
  type        = string
}

# "https://cloud.yandex.ru/docs/resource-manager/operations/cloud/get-id"
variable "cloud_id" {
  type = string
}

# "https://cloud.yandex.ru/docs/resource-manager/operations/folder/get-id"
variable "folder_id" {
  type = string
}

variable "sa_id" {
  description = "Service account ID for Yandex.Cloud"
  type        = string
}

# variable "folder_name" {
#   description = "Name of the Yandex Cloud folder to create for this project"
#   type        = string
#   default     = "cloud-15-4-hw"
# }

#**********************************************#
# "https://cloud.yandex.ru/docs/overview/concepts/geo-scope"
variable "default_zone" {
  type        = string
  default     = "ru-central1-a"
  description = "Zone for the VPC network"
}

variable "default_region" {
  type        = string
  default     = "ru-central1"
  description = "Region for the VPC network"
}

# variable "default_cidr" {
#   type        = list(string)
#   default     = ["10.0.1.0/24"]
#   description = "https://cloud.yandex.ru/docs/vpc/operations/subnet-create"
# }

# variable "public_cidr" {
#   type        = list(string)
#   default     = ["192.168.10.0/24"]
#   description = "https://cloud.yandex.ru/docs/vpc/operations/subnet-create"
# }

# variable "private_cidr" {
#   type        = list(string)
#   default     = ["192.168.20.0/24"]
#   description = "https://cloud.yandex.ru/docs/vpc/operations/subnet-create"
# }

# variable "internal_nat_ip" {
#   type        = string
#   default     = "192.168.10.254"
#   description = "Internal IP of the nat"
# }  

variable "vpc_net_name" {
  type        = string
  default     = "net"
  description = "VPC network name"
}

variable "vpc_sub_name" {
  type        = string
  default     = "subnet"
  description = "VPC subnet name"
}

# variable "vpc_public_name" {
#   type        = string
#   default     = "public-subnet"
#   description = "VPC subnet name"
# }

# variable "vpc_private_name" {
#   type        = string
#   default     = "private-subnet"
#   description = "VPC subnet name"
# }

#**********************************************#
# ssh-keygen -t ed25519
variable "ssh_key" {
  description = "Path to the public SSH key for VMs"
  type        = string
  default     = "../vault/id_ed25519.pub"
}

variable "ssh_private_key" {
  description = "Path to the private SSH key for VMs"
  type        = string
  default     = "../vault/id_ed25519"
}



#**********************************************#
# "https://yandex.cloud/ru/docs/compute/concepts/vm-platforms"
variable "vm_platform_id" {
  type        = string
  default     = "standard-v2"
}

#**********************************************#
variable "default_image" {
  description = "ID образа ОС (не семейство: семейство приводит к пересозданию машин при обновлении образа)"
  type        = string
  # default     = "ubuntu-2404-lts-oslogin"
  default     = "fd8ee8il5b8tk8oggcs0" # ubuntu-2404-lts на 2026-09-28
}
# "https://cloud.yandex.ru/docs/compute/concepts/images"
variable "vm_image_family" {
  type        = string
  # default     = "ubuntu-2404-lts-oslogin"
  default     = "ubuntu-2404-lts"
}

# variable "vm_image_id" {
#   type        = string
#   default     = "fd80mrhj8fl2oe87o4e1"
#   description = "https://cloud.yandex.ru/docs/compute/concepts/images"
# }

#**********************************************#
variable "subnets" {
  type = map(object({
    name             = optional(string, "subnet"),
    labels           = optional(map(string), {}),
    zone             = optional(string, "ru-central1-a"),
    network_id       = optional(string, ""),
    v4_cidr_blocks   = optional(list(string), ["10.0.1.0/24"]),
    route_table_name = optional(string, "")
  }))
  default = {
    "public-a" = {
      name           = "public-a"
      zone           = "ru-central1-a"
      v4_cidr_blocks = ["192.168.1.0/24"]
    },
    "public-b" = {
      name           = "public-b"
      zone           = "ru-central1-b"
      v4_cidr_blocks = ["192.168.2.0/24"]
    },
    "private-a" = {
      name             = "private-a"
      labels           = { "env" = "production" }
      zone             = "ru-central1-a"
      v4_cidr_blocks   = ["192.168.10.0/24"]
      route_table_name = "nat-rt"
    },
    "private-b" = {
      name             = "private-b"
      labels           = { "env" = "production" }
      zone             = "ru-central1-b"
      v4_cidr_blocks   = ["192.168.20.0/24"]
      route_table_name = "nat-rt"
    }
  }
  description = "Templates for reuse"
}

variable "rt" {
  type = map(object({
    name = optional(string, "rt"),
    static_routes = optional(list(object({
      destination_prefix = string
      next_hop_address   = string
    })), [])
  }))
  default = {
    "nat-rt" = {
      name = "nat-rt"
      static_routes = [
        {
          destination_prefix = "0.0.0.0/0"
          next_hop_address   = "192.168.1.254"
        }
      ]
    }
  }
}

# https://yandex.cloud/ru/docs/terraform/data-sources/vpc_security_group
# https://yandex.cloud/ru/docs/managed-kubernetes/operations/connect/security-groups
#  type of protocol: ANY, TCP, UDP, ICMP, IPV6_ICMP.
variable "sg" {
  description = "sec-rules ingress/egress"
  type = map(map(list(object({

    protocol       = string
    description    = string
    v4_cidr_blocks = list(string)
    port           = optional(number)
    from_port      = optional(number)
    to_port        = optional(number)
  }))))
  default = {
    "public" = {
      "ingress" = [
        {
          protocol       = "ANY"
          description    = "разрешить весь входящий трафик"
          v4_cidr_blocks = ["0.0.0.0/0"]
          from_port      = 0
          to_port        = 65535
      }],
      "egress" = [
        {
          protocol       = "ANY"
          description    = "разрешить весь исходящий трафик"
          v4_cidr_blocks = ["0.0.0.0/0"]
          from_port      = 0
          to_port        = 65535
      }]
    },
    "private" = {
      "ingress" = [
        {
          protocol       = "ANY"
          description    = "разрешить весь входящий трафик"
          v4_cidr_blocks = ["0.0.0.0/0"]
          from_port      = 0
          to_port        = 65535
      }],
      "egress" = [
        {
          protocol       = "ANY"
          description    = "разрешить весь исходящий трафик"
          v4_cidr_blocks = ["0.0.0.0/0"]
          from_port      = 0
          to_port        = 65535
      }]
    },
    "mysql" = {
      "ingress" = [
        {
          protocol       = "TCP"
          description    = "MySQL®"
          v4_cidr_blocks = ["192.168.10.0/24"] # В public subnet разрешаем доступ к MySQL® из NAT и bastion
          port           = 3306
      }]
    }
  }
}

#**********************************************#
variable "vm_res_type" {
  type = map(object({
    cpu           = optional(number, 1),
    ram           = optional(number, 1),
    core_fraction = optional(number, 20),
    disk_volume   = optional(number, 10) # depricated, use vm_boot_disks instead
  }))
  default = {
    "default" = {
      cpu = 2
      ram = 4
    },
    "nat" = {
      cpu           = 2
      ram           = 4
      core_fraction = 20
      # disk_volume  = 20
    },
    "admin" = {
      cpu           = 4
      ram           = 8
      core_fraction = 20
      # disk_volume  = 20
    },
    "bastion" = {
      cpu = 2
      ram = 4
      core_fraction = 20
    },
    "master" = {
      cpu           = 4
      ram           = 8
      core_fraction = 20
      # disk_volume  = 20
    },
    "worker" = {
      cpu = 2
      ram = 4
      core_fraction = 20
    }
  }
  description = "Templates for reuse"
}

variable "vm_boot_disks" {
  type = map(object({
    disk_name = optional(string, ""),
    disk_type = optional(string, "network-hdd"),
    disk_size = optional(number, 10),
    disk_mode = optional(string, "READ_WRITE"),
    image_id  = optional(string, ""),
  }))
  default = {
    "default" = {
      disk_name = "disk-default"
      disk_type = "network-hdd"
      disk_size = 20
      # image_id = "fd827b91d99psvq5fjit"
    },
    "bastion" = {
      disk_name = "disk-bastion"
      disk_type = "network-hdd"
      disk_size = 10
    },
    "nat" = {
      disk_name = "disk-nat"
      disk_type = "network-hdd"
      disk_size = 40
      image_id  = "fd80mrhj8fl2oe87o4e1"
    },
    "master" = {
      disk_name = "disk-master"
      disk_type = "network-hdd"
      disk_size = 16
    },
    "worker" = {
      disk_name = "disk-worker"
      disk_type = "network-hdd"
      disk_size = 30
    },
    "admin" = {
      disk_name = "disk-admin"
      disk_type = "network-hdd"
      disk_size = 20
      # image_id  = "fd80k75pl3772cl0jcc8"
    }
  }
  description = "Templates for reuse"
}

variable "vms" {
  type = list(object({
    vm_name           = string,
    vm_role       = optional(string, "default"),
    vm_subnet         = optional(string, "default"),
    vm_security_group = optional(string, "private"),
    sa_name           = optional(string, ""),
    # serial_port_enable = optional(bool, true),
    nat_enable  = optional(bool, false),
    user_name   = optional(string, "ubuntu"),
    metadata    = optional(map(string), { "enable-oslogin" = "false", "ssh-keys" = "../vault/id_ed25519.pub", "user-data" = "" }),
    internal_ip = optional(string, ""),
    external_ip = optional(string, ""),
    image_id    = optional(string, "") # depricated, use vm_boot_disks instead
  }))
  default = [
    { vm_name   = "nat", nat_enable = true, vm_role = "nat",
      vm_subnet = "public-a", vm_security_group = "public",
    internal_ip = "192.168.1.254" },
    { vm_name = "bastion", nat_enable = true, vm_role = "bastion",
    vm_subnet = "public-a", vm_security_group = "public", user_name = "ubuntu" },
    { vm_name = "admin", nat_enable = false, vm_role = "admin",
      vm_subnet = "private-a", vm_security_group = "private", 
      sa_name = "k8s_admin_sa"},
    { vm_name = "k8s-master-01", vm_subnet = "private-a", vm_role = "master" },
    { vm_name = "k8s-master-02", vm_subnet = "private-b", vm_role = "master" },
    { vm_name = "k8s-master-03", vm_subnet = "private-a", vm_role = "master" },
    { vm_name = "k8s-worker-01", vm_subnet = "private-a", vm_role = "worker" },
    { vm_name = "k8s-worker-02", vm_subnet = "private-b", vm_role = "worker" },
    { vm_name = "k8s-worker-03", vm_subnet = "private-a", vm_role = "worker" }
  ]
  description = "List of VMs"
}

#**********************************************#
# variable "sg_name" {
#   type    = string
#   default = "sg_general"
# }

variable "instance_templates" {
  description = "Templates for instance creation"
  type = map(object({
    platform_id                   = string
    metadata                      = map(string)
    scheduling_policy_preemptible = bool

    vm_res_type = string
    # boot_disk = object({
    #   mode     = string
    #   name     = string
    #   image_id = string
    #   size     = number
    #   type     = string
    # })
  }))
  default = {
    "worker" = {
      platform_id                   = "standard-v3"
      metadata                      = { user-data = "cloud_config.yaml" }
      scheduling_policy_preemptible = true
      vm_res_type                   = "worker"
    }
  }
}

variable "vm_group" {
  description = "Configuration for the VM group"
  type = map(object({
    vm_group_name                  = string
    allocation_policy_zone         = optional(string, "ru-central1-b")
    application_load_balancer_name = string
    deletion_protection            = optional(bool, false)
    vm_res_type                    = string
    vm_subnet_name                 = string
    deploy_policy = object({
      max_creating     = optional(number, 5)
      max_deleting     = optional(number, 2)
      max_unavailable  = optional(number, 1)
      max_expansion    = optional(number, 1)
      startup_duration = optional(number, 300)
      strategy         = optional(string, "proactive")
    })
  }))
  default = {
    "wrkr-01" = {
      vm_group_name                  = "wrkr-01"
      application_load_balancer_name = "alb-wrkrs"
      vm_res_type                    = "worker"
      vm_subnet_name                 = "private-a"
      deploy_policy                  = {}
    },
    "wrkr-02" = {
      vm_group_name                  = "wrkr-02"
      application_load_balancer_name = "alb-wrkrs"
      vm_res_type                    = "worker"
      vm_subnet_name                 = "private-b"
      deploy_policy                  = {}
    },
    "wrkr-03" = {
      vm_group_name                  = "wrkr-03"
      application_load_balancer_name = "alb-wrkrs"
      vm_res_type                    = "worker"
      vm_subnet_name                 = "private-d"
      deploy_policy                  = {}
    }


  }
}

#**********************************************#
# https://yandex.cloud/ru/docs/managed-mysql/concepts/instance-types
variable "cluster_host" {
  type = map(object({
    cpu                = string
    resource_preset_id = optional(string, "b1.medium")
    disk_type_id       = optional(string, "network-hdd")
    disk_size          = optional(number, 20)
  }))
  default = {
    "b1m" = {
      cpu                = "Intel Broadwell"
      resource_preset_id = "b1.medium"
      disk_type_id       = "network-hdd"
      disk_size          = 20
    },
    "b2m" = {
      cpu                = "Intel Cascade Lake"
      resource_preset_id = "b2.medium"
      disk_type_id       = "network-hdd"
      disk_size          = 20
    }
  }
}

variable "mycl_base" {
  type = object({
    database_name = optional(string, "netology_db")
  })
  default = {}
}

variable "mycl_user_password" {
  sensitive = true
  type      = string
  default   = ""
}

variable "mycl_user" {
  type = object({
    name              = optional(string, "sa")
    password          = optional(string, "")
    generate_password = optional(bool, true)
    perm_roles        = optional(list(string), ["ALL"])
  })
  default = {}
}

variable "mycl_hosts" {
  type = map(object({
    sn_name = string
    # zone             = string
    # subnet_id        = string
    assign_public_ip = optional(bool, false)
    priority         = optional(number, 0)
    backup_priority  = optional(number, 0)
  }))
  default = {
    "host1" = {
      sn_name = "private-a"
    },
    "host2" = {
      sn_name = "private-b"
    }
  }
}

# MySQL Cluster configuration
variable "mycl" {
  description = "Yandex Managed MySQL cluster configuration"
  type = object({
    name                      = string
    environment               = string
    version                   = string
    security_group_names      = optional(list(string), ["mysql"])
    backup_retain_period_days = optional(number, 7)

    resources = optional(string, "b1m")

    maintenance_window = object({
      type = optional(string, "WEEKLY")
      day  = optional(string, "MON")
      hour = optional(number, 23)
    })
    backup_window_start = object({
      hours   = optional(number, 23)
      minutes = optional(number, 59)
    })
    disk_size_autoscaling = object({
      disk_size_limit           = optional(number, 100)
      emergency_usage_threshold = optional(number, 90)
      planned_usage_threshold   = optional(number, 80)
    })
  })
  default = {
    name                  = "mysql439"
    environment           = "PRESTABLE"
    version               = "8.0"
    maintenance_window    = {}
    backup_window_start   = {}
    disk_size_autoscaling = {}
  }
}
#**********************************************#
variable "k8cl" {
  description = ""
  type = object({
    name                     = string
    release_channel          = optional(string, "STABLE")
    master_region            = optional(string, "ru-central1")
    master_sg_name           = string
    worker_sg_name           = string
    maintenance_auto_upgrade = optional(bool, true)

    master = list(object({
      subnet_name = string
      zone        = string
    }))
    maintenance_windows = list(object({
      day        = string
      start_time = string
      duration   = string
    }))
    # kms_provider_name = string
  })
  default = {
    name = "k8s-cluster"

    master = [
      { subnet_name = "private-a"
        zone        = "ru-central1-a" # deprecated, pull from subnet instead
      },
      { subnet_name = "private-b"
        zone        = "ru-central1-b" # deprecated, pull from subnet instead
      },
      { subnet_name = "private-d"
        zone        = "ru-central1-d" # deprecated, pull from subnet instead
      }
    ]
    master_sg_name = "k8s-master-sg"
    worker_sg_name = "k8s-worker-sg"
    # kms_provider_name = "k8s-kms-provider"
    maintenance_windows = [{
      day        = "monday"
      start_time = "15:00"
      duration   = "3h"
    }]
  }
}

variable "k8s_node_groups" {
  description = "Kubernetes node groups configuration"
  type = map(object({
    name                   = string
    instance_template_name = string
    subnet_name            = string
    # subnet_lb = optional(string, "production")
    labels = optional(map(string), {})

    platform_id                   = optional(string, "standard-v3")
    container_type                = optional(string, "containerd")
    res_type                      = optional(string, "worker")
    scheduling_policy_preemptible = optional(bool, true)
    # security_group_name = string
    # node_count = number

    auto_scale = optional(object({
      min     = optional(number, 1)
      max     = optional(number, 3)
      initial = optional(number, 1)
    }))
    deploy_policy = optional(object({
      max_unavailable = optional(number, 1)
      max_expansion   = optional(number, 1)
    }))
    maintenance_auto_upgrade = optional(bool, true)
    maintenance_auto_repair  = optional(bool, true)
    maintenance_windows = list(object({
      day        = optional(string, "monday")
      start_time = optional(string, "00:00")
      duration   = optional(string, "1h")
    }))

  }))
  default = {
    "node-group-01" = {
      name                   = "node-group-01"
      instance_template_name = "worker"
      subnet_name            = "private-a"
      res_type               = "worker"
      # security_group_name = "k8s-worker-sg"
      # node_count = 3
      auto_scale          = {}
      deploy_policy       = {}
      maintenance_windows = [{}]
    }
  }
}

#**********************************************#
variable "kms_key" {
  description = "key-a"
  type = object({
    default_algorithm = optional(string, "AES_256")
    folder_id         = optional(string, null)
    name              = string
    rotation_period   = optional(string, null)
  })
  default = {
    name = "basket-encryption-key"
  }
}
#**********************************************#
variable "k8cl_sa" {
  type = object({
    name        = optional(string, "k8cl-sa")
    description = optional(string, "Service account for Kubernetes cluster")
    roles = optional(list(string), [
      "k8s.clusters.agent",
      "vpc.publicAdmin",
      "container-registry.images.puller",
      "kms.keys.encrypterDecrypter"
    ])
  })
  default = {}
}

variable "k8s_admin_sa" {
  type = object({
    name        = optional(string, "k8s-admin-sa")
    description = optional(string, "Service account for Kubernetes administration")
    roles = optional(list(string), [
      "k8s.cluster-api.cluster-admin",
      "k8s.viewer"
    ])
  })
  default = {}
}

#**********************************************#
variable "docker" {
  description = "docker registry config variable"
  type = object({
    registry_name = optional(string, "main")
    repo_name = optional(string, "hub")
  })
  default = {}
}
