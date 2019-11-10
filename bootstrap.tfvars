azure_location = "West Europe"
azure_resource_group_name = "okd-cluster-25"
azure_resources_prefix = "okd"
azure_storage_prefix = "okd000"
azure_address_space = "172.16.0.0/16"
azure_address_prefix_master = "172.16.1.0/24"
azure_address_prefix_infra = "172.16.2.0/24"
azure_address_prefix_node = "172.16.3.0/24"
openshift_master_internal_load_balancer = "172.16.1.240"
openshift_master_count = "3"
openshift_infra_count = "3"
openshift_node_count = "3"
openshift_node_vm_size = "Standard_B2s"
openshift_master_vm_size = "Standard_B2s"
openshift_infra_vm_size = "Standard_B2ms"
openshift_bastion_vm_size = "Standard_B2ms"
openshift_master_domain = "openshift.mydomain.com"
openshift_router_domain = "mydomain.com"
openshift_os_image_publisher = "OpenLogic"
openshift_os_image_offer = "CentOS"
openshift_os_image_sku = "7.7"
openshift_os_image_version = "latest"
openshift_vm_admin_user = "okd"
