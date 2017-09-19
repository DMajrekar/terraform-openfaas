variable "slave-count"  { default = "2" }
variable "local-cidr"   { default = "192.168.201.0/24" }
variable "image_id"     { default = "d5d43ba0-82e9-43de-8883-5ebaf07bf3e3" }
variable "kube-token"   { default = "7a5623.f26b494acd4c399a" }
variable "public_key"   { default = "" }
variable "access_cidr"  { default = "" }

output "kube-master-ip" { value = "${openstack_compute_floatingip_v2.kube-master.address}" }


provider "openstack" {
  auth_url = "https://auth.civo.com/v3"
}

resource "openstack_compute_keypair_v2" "kube" {
  name       = "kube"
  public_key = "${var.public_key}"
}

resource "openstack_compute_floatingip_v2" "kube-master" {
  pool = "ext-net"
}

resource "openstack_compute_secgroup_v2" "kube-master" {
  name = "kube-master"
  description = "Kube Master Node"

  # SSH Access
  rule {
    from_port   = 22
    to_port     = 22
    ip_protocol = "tcp"
    cidr        = "${var.access_cidr}"
  }

  # Access to/from Kube Network
  rule {
    from_port   = 1
    to_port     = 65535
    ip_protocol = "tcp"
    cidr        = "${var.local-cidr}"
  }

  rule {
    from_port   = 1
    to_port     = 65535
    ip_protocol = "udp"
    cidr        = "${var.local-cidr}"
  }

  # Access to OpenFaaS
  rule {
    from_port   = 31112
    to_port     = 31119
    ip_protocol = "tcp"
    cidr        = "${var.access_cidr}"
  }

}

resource "openstack_compute_secgroup_v2" "kube-slave" {
  name = "kube-slave"
  description = "Kube Slave Nodes"

  # Full Access from local cidr
  rule {
    from_port   = 1
    to_port     = 65535
    ip_protocol = "tcp"
    cidr        = "${var.local-cidr}"
  }

  rule {
    from_port   = 1
    to_port     = 65535
    ip_protocol = "udp"
    cidr        = "${var.local-cidr}"
  }

}

resource "openstack_networking_network_v2" "network" {
  name = "kube-network"
}

resource "openstack_networking_subnet_v2" "subnet" {
  name       = "kube-subnet"
  network_id = "${openstack_networking_network_v2.network.id}"
  cidr        = "${var.local-cidr}"
  dns_nameservers = ["8.8.8.8"]
}

resource "openstack_networking_router_v2" "router" {
  name             = "kube-router"
  external_gateway = "aec08ef5-f630-412f-b41c-f8b81df35eea"
}

resource "openstack_networking_router_interface_v2" "int_1" {
  router_id = "${openstack_networking_router_v2.router.id}"
  subnet_id = "${openstack_networking_subnet_v2.subnet.id}"
}

resource "openstack_compute_instance_v2" "kube-master" {
  name            = "kube-master"
  image_id        = "${var.image_id}"
  flavor_name     = "g1.xsmall"
  key_pair        = "${openstack_compute_keypair_v2.kube.name}"
  security_groups = ["default", "${openstack_compute_secgroup_v2.kube-master.name}"]

  user_data       = "${data.template_file.cloud-config-master.rendered}"

  network {
    name = "${openstack_networking_network_v2.network.name}"
  }
}

resource "openstack_compute_floatingip_associate_v2" "fip_1" {
  floating_ip = "${openstack_compute_floatingip_v2.kube-master.address}"
  instance_id = "${openstack_compute_instance_v2.kube-master.id}"
}

data "template_file" "cloud-config-master" {
  template = "${file("${path.module}/kube-master.yml")}"
  vars {
    public-ip  = "${openstack_compute_floatingip_v2.kube-master.address}"
    kube-token = "${var.kube-token}"
  }
}

resource "openstack_compute_instance_v2" "kube-slave" {
  count    = "${var.slave-count}"

  depends_on      = ["openstack_compute_instance_v2.kube-master"]

  name            = "${format("kube-slave-%02d", count.index + 1)}"
  image_id        = "${var.image_id}"
  flavor_name     = "g1.small"
  key_pair        = "${openstack_compute_keypair_v2.kube.name}"
  security_groups = ["default", "${openstack_compute_secgroup_v2.kube-slave.name}"]

  user_data       = "${element(data.template_file.cloud-config-slave.*.rendered, count.index)}"

  network {
    name = "${openstack_networking_network_v2.network.name}"
  }
}

data "template_file" "cloud-config-slave" {
  count = "${var.slave-count}"
  template = "${file("${path.module}/kube-slave.yml")}"

  vars {
    hostname   = "${format("kube-slave-%02d", count.index + 1)}"
    master-ip  = "${openstack_compute_instance_v2.kube-master.network.0.fixed_ip_v4}"
    kube-token = "${var.kube-token}"
  }

}
