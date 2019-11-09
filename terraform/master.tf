resource "random_string" "master" {
  length = 16
  special = false
  upper = false
}

resource "azurerm_public_ip" "master" {
  name                         = "${var.azure_resources_prefix}-master-public-ip"
  location                     = "${var.azure_location}"
  resource_group_name          = "${azurerm_resource_group.openshift.name}"
  allocation_method = "Static"
  domain_name_label            = "ocp-${random_string.master.result}"
  sku                          = "Standard"
}

resource "azurerm_availability_set" "master" {
  name                = "${var.azure_resources_prefix}-master-availability-set"
  location            = "${var.azure_location}"
  resource_group_name = "${azurerm_resource_group.openshift.name}"
  managed             = true
}

#resource "azurerm_dns_a_record" "${var.azure_resources_prefix}-master-private-load-balancer" {
#  name                = "master-private-lb"
#  zone_name           = "${azurerm_dns_zone.openshift.name}"
#  resource_group_name = "${azurerm_resource_group.openshift.name}"
#  ttl                 = 300
#  records             = ["10.0.1.250"]
#}

resource "azurerm_lb" "master" {
  name                = "${var.azure_resources_prefix}-master-load-balancer"
  location            = "${var.azure_location}"
  resource_group_name = "${azurerm_resource_group.openshift.name}"
  sku                 = "Standard"

  frontend_ip_configuration {
    name                          = "default"
    public_ip_address_id          = "${azurerm_public_ip.master.id}"
    private_ip_address_allocation = "dynamic"
  }
}

resource "azurerm_lb_backend_address_pool" "master" {
  name                = "${var.azure_resources_prefix}-master-address-pool"
  resource_group_name = "${azurerm_resource_group.openshift.name}"
  loadbalancer_id     = "${azurerm_lb.master.id}"
}

resource "azurerm_lb_rule" "master-8443-8443" {
  name                    = "master-lb-rule-8443-8443"
  resource_group_name     = "${azurerm_resource_group.openshift.name}"
  loadbalancer_id         = "${azurerm_lb.master.id}"
  backend_address_pool_id = "${azurerm_lb_backend_address_pool.master.id}"
  probe_id                = "${azurerm_lb_probe.master.id}"
  protocol                       = "tcp"
  frontend_port                  = 8443
  backend_port                   = 8443
  idle_timeout_in_minutes        = 10
  frontend_ip_configuration_name = "default"
}

resource "azurerm_lb_probe" "master" {
  name                = "master-lb-probe-8443-up"
  resource_group_name = "${azurerm_resource_group.openshift.name}"
  loadbalancer_id     = "${azurerm_lb.master.id}"
  protocol            = "Https"
  request_path        = "/healthz"
  port                = 8443
}

resource "azurerm_network_security_group" "master" {
  name                = "${var.azure_resources_prefix}-master-security-group"
  location            = "${var.azure_location}"
  resource_group_name = "${azurerm_resource_group.openshift.name}"
}

resource "azurerm_network_security_rule" "master-8443" {
  name                        = "master-8443"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = 8443
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = "${azurerm_resource_group.openshift.name}"
  network_security_group_name = "${azurerm_network_security_group.master.name}"
}

resource "azurerm_network_interface" "master" {
  count                     = "${var.openshift_master_count}"
  name                      = "${var.azure_resources_prefix}-master-nic-${count.index + 1}"
  location                  = "${var.azure_location}"
  resource_group_name       = "${azurerm_resource_group.openshift.name}"
  network_security_group_id = "${azurerm_network_security_group.master.id}"

  ip_configuration {
    name                                    = "default"
    subnet_id                               = "${azurerm_subnet.master.id}"
    private_ip_address_allocation           = "dynamic"
    load_balancer_backend_address_pools_ids = ["${azurerm_lb_backend_address_pool.master.id}"]
  }
}

resource "azurerm_virtual_machine" "master" {
  count                 = "${var.openshift_master_count}"
  name                  = "${var.azure_resources_prefix}-master-vm-${count.index + 1}"
  location              = "${var.azure_location}"
  resource_group_name   = "${azurerm_resource_group.openshift.name}"
  network_interface_ids = ["${element(azurerm_network_interface.master.*.id, count.index)}"]
  vm_size               = "${var.openshift_master_vm_size}"
  availability_set_id   = "${azurerm_availability_set.master.id}"

  storage_image_reference {
    publisher = "${var.openshift_os_image_publisher}"
    offer     = "${var.openshift_os_image_offer}"
    sku       = "${var.openshift_os_image_sku}"
    version   = "${var.openshift_os_image_version}"
  }

  storage_os_disk {
    name              = "${var.azure_resources_prefix}-master-vm-os-disk-${count.index + 1}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_data_disk {
    name              = "${var.azure_resources_prefix}-master-vm-data-disk-${count.index + 1}"
    create_option     = "Empty"
    managed_disk_type = "Standard_LRS"
    lun               = 0
    disk_size_gb      = 20
  }

  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  os_profile {
    computer_name  = "master${count.index + 1}"
    admin_username = "${var.openshift_vm_admin_user}"
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path = "/home/${var.openshift_vm_admin_user}/.ssh/authorized_keys"
      key_data = "${file("${path.module}/../certs/openshift.pub")}"
    }
  }
}
