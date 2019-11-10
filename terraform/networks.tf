resource "azurerm_virtual_network" "openshift" {
  name          = "${var.azure_resources_prefix}-virtual-network"
  address_space = ["${var.azure_address_space}"]
  location      = "${var.azure_location}"
  resource_group_name = "${azurerm_resource_group.openshift.name}"
}

resource "azurerm_subnet" "master" {
  name                 = "${var.azure_resources_prefix}-master-subnet"
  resource_group_name  = "${azurerm_resource_group.openshift.name}"
  virtual_network_name = "${azurerm_virtual_network.openshift.name}"
  address_prefix       = "${var.azure_address_prefix_master}"
}

resource "azurerm_subnet" "infra" {
  name                 = "${var.azure_resources_prefix}-infra-subnet"
  resource_group_name  = "${azurerm_resource_group.openshift.name}"
  virtual_network_name = "${azurerm_virtual_network.openshift.name}"
  address_prefix       = "${var.azure_address_prefix_infra}"
}

resource "azurerm_subnet" "node" {
  name                 = "${var.azure_resources_prefix}-node-subnet"
  resource_group_name  = "${azurerm_resource_group.openshift.name}"
  virtual_network_name = "${azurerm_virtual_network.openshift.name}"
  address_prefix       = "${var.azure_address_prefix_node}"
}

#resource "azurerm_dns_zone" "openshift" {
#  name                              = "openshift.local"
#  resource_group_name               = "${azurerm_resource_group.openshift.name}"
#  azurerm_private_dns_zone                         = "Private"
#  registration_virtual_network_ids  = ["${azurerm_virtual_network.openshift.id}"]
#}

