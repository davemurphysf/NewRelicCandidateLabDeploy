provider "azurerm" {
  # More information on the authentication methods supported by
  # the AzureRM Provider can be found here:
  # http://terraform.io/docs/providers/azurerm/index.html
  
  subscription_id = "${var.subscription_id}"
  #client_id       = "${var.client_id}"
  #client_secret   = "${var.client_secret}"
  tenant_id       = "${var.tenant_id}"
  version           = "=1.21.0"
}

locals {
  cname = "${trimspace(lower(chomp("${var.candidate_name}")))}"
}

resource "azurerm_resource_group" "rg" {
  name     = "${local.cname}-${var.resource_group}"
  location = "${var.location}"
  tags     = "${var.tags}"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.virtual_network_name}"
  location            = "${var.location}"
  address_space       = ["${var.address_space}"]
  resource_group_name = "${azurerm_resource_group.rg.name}"
  tags                = "${var.tags}"
}

resource "azurerm_subnet" "internal-subnet" {
  name                 = "${var.rg_prefix}-internal-subnet"
  virtual_network_name = "${azurerm_virtual_network.vnet.name}"
  resource_group_name  = "${azurerm_resource_group.rg.name}"
  address_prefix       = "${var.internal_subnet_prefix}"
}

resource "azurerm_subnet" "external-subnet" {
  name                 = "${var.rg_prefix}-external-subnet"
  virtual_network_name = "${azurerm_virtual_network.vnet.name}"
  resource_group_name  = "${azurerm_resource_group.rg.name}"
  address_prefix       = "${var.external_subnet_prefix}"
}

resource "azurerm_public_ip" "app-pip" {
  name                         = "${var.rg_prefix}-app-ip"
  location                     = "${var.location}"
  resource_group_name          = "${azurerm_resource_group.rg.name}"
  allocation_method            = "Dynamic"
  domain_name_label            = "${local.cname}-${var.dns_name}-app"
  tags                         = "${var.tags}"
}

resource "azurerm_network_security_group" "app-ext-nsg" {
  name                = "${var.rg_prefix}-app-ext-nsg"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"

  security_rule {
    name                       = "allow_8080"
    description                = "Allow 8080 access"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow_HTTP"
    description                = "Allow HTTP access"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow_SSH"    
    description                = "Allow SSH access"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_storage_account" "stor" {
  name                     = "${local.cname}sg"
  location                 = "${var.location}"
  resource_group_name      = "${azurerm_resource_group.rg.name}"
  account_tier             = "${var.storage_account_tier}"
  account_replication_type = "${var.storage_replication_type}"
}
