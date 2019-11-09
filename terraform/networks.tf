resource "azurerm_virtual_network" "openshift" {
  name          = "${var.azure_resources_prefix}-virtual-network"
  address_space = ["10.0.0.0/16"]
  location      = "${var.azure_location}"
  resource_group_name = "${azurerm_resource_group.openshift.name}"
}

resource "azurerm_subnet" "master" {
  name                 = "${var.azure_resources_prefix}-master-subnet"
  resource_group_name  = "${azurerm_resource_group.openshift.name}"
  virtual_network_name = "${azurerm_virtual_network.openshift.name}"
  address_prefix       = "10.0.1.0/24"
}

resource "azurerm_subnet" "infra" {
  name                 = "${var.azure_resources_prefix}-infra-subnet"
  resource_group_name  = "${azurerm_resource_group.openshift.name}"
  virtual_network_name = "${azurerm_virtual_network.openshift.name}"
  address_prefix       = "10.0.2.0/24"
}

resource "azurerm_subnet" "node" {
  name                 = "${var.azure_resources_prefix}-node-subnet"
  resource_group_name  = "${azurerm_resource_group.openshift.name}"
  virtual_network_name = "${azurerm_virtual_network.openshift.name}"
  address_prefix       = "10.0.3.0/24"
}

#resource "azurerm_dns_zone" "openshift" {
#  name                              = "openshift.local"
#  resource_group_name               = "${azurerm_resource_group.openshift.name}"
#  azurerm_private_dns_zone                         = "Private"
#  registration_virtual_network_ids  = ["${azurerm_virtual_network.openshift.id}"]
#}
