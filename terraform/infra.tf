resource "azurerm_public_ip" "infra" {
  name                 = "${var.azure_resources_prefix}-infra-public-ip"
  location             = "${var.azure_location}"
  resource_group_name  = "${azurerm_resource_group.openshift.name}"
  allocation_method    = "Static"
}

resource "azurerm_availability_set" "infra" {
  name                = "${var.azure_resources_prefix}-infra-availability-set"
  location            = "${var.azure_location}"
  resource_group_name = "${azurerm_resource_group.openshift.name}"
  managed             = true
}

resource "azurerm_lb" "infra" {
  name                = "${var.azure_resources_prefix}-infra-load-balancer"
  location            = "${var.azure_location}"
  resource_group_name = "${azurerm_resource_group.openshift.name}"

  frontend_ip_configuration {
    name                          = "default"
    public_ip_address_id          = "${azurerm_public_ip.infra.id}"
    private_ip_address_allocation = "dynamic"
  }
}

resource "azurerm_lb_backend_address_pool" "infra" {
  name                = "${var.azure_resources_prefix}-infra-address-pool"
  resource_group_name = "${azurerm_resource_group.openshift.name}"
  loadbalancer_id     = "${azurerm_lb.infra.id}"
}

resource "azurerm_lb_rule" "infra-80-80" {
  name                    = "infra-lb-rule-80-80"
  resource_group_name     = "${azurerm_resource_group.openshift.name}"
  loadbalancer_id         = "${azurerm_lb.infra.id}"
  backend_address_pool_id = "${azurerm_lb_backend_address_pool.infra.id}"
  protocol                       = "tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "default"
}

resource "azurerm_lb_rule" "infra-443-443" {
  name                    = "infra-lb-rule-443-443"
  resource_group_name     = "${azurerm_resource_group.openshift.name}"
  loadbalancer_id         = "${azurerm_lb.infra.id}"
  backend_address_pool_id = "${azurerm_lb_backend_address_pool.infra.id}"
  protocol                       = "tcp"
  frontend_port                  = 443
  backend_port                   = 443
  frontend_ip_configuration_name = "default"
}

resource "azurerm_network_security_group" "infra" {
  name                = "${var.azure_resources_prefix}-infra-security-group"
  location            = "${var.azure_location}"
  resource_group_name = "${azurerm_resource_group.openshift.name}"
}

resource "azurerm_network_security_rule" "infra-http" {
  name                        = "infra-http"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "TCP"
  source_port_range           = "*"
  destination_port_range      = 80
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = "${azurerm_resource_group.openshift.name}"
  network_security_group_name = "${azurerm_network_security_group.infra.name}"
}

resource "azurerm_network_security_rule" "infra-https" {
  name                        = "infra-https"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = 443
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = "${azurerm_resource_group.openshift.name}"
  network_security_group_name = "${azurerm_network_security_group.infra.name}"
}

resource "azurerm_network_interface" "infra" {
  count                     = "${var.openshift_infra_count}"
  name                      = "${var.azure_resources_prefix}-infra-nic-0${count..index + 1}"
  location                  = "${var.azure_location}"
  resource_group_name       = "${azurerm_resource_group.openshift.name}"
  network_security_group_id = "${azurerm_network_security_group.infra.id}"

  ip_configuration {
    name                                    = "default"
    subnet_id                               = "${azurerm_subnet.infra.id}"
    private_ip_address_allocation           = "dynamic"
    load_balancer_backend_address_pools_ids = ["${azurerm_lb_backend_address_pool.infra.id}"]
  }
}

resource "azurerm_virtual_machine" "infra" {
  count                 = "${var.openshift_infra_count}"
  name                  = "${var.azure_resources_prefix}-infra-0${count..index + 1}"
  location              = "${var.azure_location}"
  resource_group_name   = "${azurerm_resource_group.openshift.name}"
  network_interface_ids = ["${element(azurerm_network_interface.infra.*.id, count.index)}"]
  vm_size               = "${var.openshift_infra_vm_size}"
  availability_set_id   = "${azurerm_availability_set.infra.id}"

  storage_image_reference {
    publisher = "${var.openshift_os_image_publisher}"
    offer     = "${var.openshift_os_image_offer}"
    sku       = "${var.openshift_os_image_sku}"
    version   = "${var.openshift_os_image_version}"
  }

  storage_os_disk {
    name              = "${var.azure_resources_prefix}-infra-vm-os-disk-0${count..index + 1}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_data_disk {
    name              = "${var.azure_resources_prefix}-infra-vm-docker-disk-0${count..index + 1}"
    create_option     = "Empty"
    managed_disk_type = "Standard_LRS"
    lun               = 0
    disk_size_gb      = 50
  }

  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  os_profile {
    computer_name  = "infra0${count..index + 1}"
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
