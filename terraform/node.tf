resource "azurerm_network_interface" "node" {
  count               = "${var.openshift_node_count}"
  name                = "${var.azure_resources_prefix}-node-nic-0${count.index + 1}"
  location            = "${var.azure_location}"
  resource_group_name = "${azurerm_resource_group.openshift.name}"

  ip_configuration {
    name                          = "default"
    subnet_id                     = "${azurerm_subnet.node.id}"
    private_ip_address_allocation = "dynamic"
  }
}

resource "azurerm_storage_container" "node" {
  count                 = "${var.openshift_node_count}"
  name                  = "node-0${count.index + 1}"
  resource_group_name   = "${azurerm_resource_group.openshift.name}"
  storage_account_name  = "${azurerm_storage_account.openshift.name}"
  container_access_type = "private"
}

resource "azurerm_virtual_machine" "node" {
  count                 = "${var.openshift_node_count}"
  name                  = "${var.azure_resources_prefix}-node-0${count.index + 1}"
  location              = "${var.azure_location}"
  resource_group_name   = "${azurerm_resource_group.openshift.name}"
  network_interface_ids = ["${element(azurerm_network_interface.node.*.id, count.index)}"]
  vm_size               = "${var.openshift_node_vm_size}"

  storage_image_reference {
    publisher = "${var.openshift_os_image_publisher}"
    offer     = "${var.openshift_os_image_offer}"
    sku       = "${var.openshift_os_image_sku}"
    version   = "${var.openshift_os_image_version}"
  }

  storage_os_disk {
    name              = "${var.azure_resources_prefix}-node-vm-os-disk-0${count.index + 1}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_data_disk {
    name              = "${var.azure_resources_prefix}-node-vm-docker-disk-0${count.index + 1}"
    create_option     = "Empty"
    managed_disk_type = "Standard_LRS"
    lun               = 0
    disk_size_gb      = 100
  }

  storage_data_disk {
    name              = "${var.azure_resources_prefix}-node-vm-ephemeral-disk-0${count.index + 1}"
    create_option     = "Empty"
    managed_disk_type = "Standard_LRS"
    lun               = 1
    disk_size_gb      = 100
  }

  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  os_profile {
    computer_name  = "node0${count.index + 1}"
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
