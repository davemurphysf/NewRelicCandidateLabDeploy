data "template_file" "could-init" {
    template = "${file("cloud-init.sh")}"
    vars = {
        pw_expiration = "${var.expiration}"
        password = "${var.password}"
        username = "${var.username}"
    }
}

resource "azurerm_network_interface" "app-ext-nic" {
    name                = "${var.rg_prefix}-app-ext-nic"
    location            = "${var.location}"
    resource_group_name = "${azurerm_resource_group.rg.name}"
    network_security_group_id = "${azurerm_network_security_group.app-ext-nsg.id}"

    ip_configuration {
        name                          = "${var.rg_prefix}-app-ext-ipconfig"
        subnet_id                     = "${azurerm_subnet.external-subnet.id}"
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = "${azurerm_public_ip.app-pip.id}"
    }
}

resource "azurerm_virtual_machine" "app" {
    name                                = "${local.cname}-${var.rg_prefix}-app-vm"
    location                            = "${var.location}"
    resource_group_name                 = "${azurerm_resource_group.rg.name}"
    vm_size                             = "${var.vm_size}"
    primary_network_interface_id        = "${azurerm_network_interface.app-ext-nic.id}"
    network_interface_ids               = ["${azurerm_network_interface.app-ext-nic.id}"]
    delete_os_disk_on_termination       = true
    delete_data_disks_on_termination    = true
    tags                                = "${var.tags}"

    storage_image_reference {
        id = "/subscriptions/96e98080-e35c-4963-a6e8-9748d470c233/resourceGroups/nr-candidate-lab-images/providers/Microsoft.Compute/images/ese-candidate-lab-02222019-centralus"
    }

    storage_os_disk {
        name              = "${var.hostname}-app-osdisk"
        managed_disk_type = "Standard_LRS"
        caching           = "ReadWrite"
        create_option     = "FromImage"
    }

    os_profile {
        computer_name   = "${var.hostname}"
        admin_username  = "${var.admin_username}"
        custom_data     = "${data.template_file.could-init.rendered}"
    }

    os_profile_linux_config {
        disable_password_authentication = true

        ssh_keys {
        path     = "/home/${var.admin_username}/.ssh/authorized_keys"
        key_data = "${file("~/.ssh/id_rsa.pub")}"
        }
    }

    boot_diagnostics {
        enabled     = true
        storage_uri = "${azurerm_storage_account.stor.primary_blob_endpoint}"
    }

    connection {
        type            = "ssh"
        bastion_host    = "${azurerm_public_ip.bastion-pip.fqdn}"
        bastion_user    = "${var.admin_username}" 
        bastion_private_key = "${file("~/.ssh/id_rsa")}"
        user            = "${var.admin_username}"        
        host            = "${azurerm_network_interface.app-ext-nic.private_ip_address}"
        private_key     = "${file("~/.ssh/id_rsa")}"
        timeout         = "5m"
    }
}