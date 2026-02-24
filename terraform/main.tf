# heart of the configuration. It defines the actual infrastructure resources you want to create 
# (resource groups, VMs, storage accounts, etc.)

resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}-ResourceGroup"
  location = var.location

  tags = {
    environment = "storm"
  }
}

# azure vnets

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}-Vnet"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
}

# azure virtual machines with a system managed identity enabled

resource "azurerm_subnet" "main" {
  name                 = "${var.prefix}-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "main" {
  name                = "${var.prefix}-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "allow-rdp"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "standalone" {
  name                = "${var.prefix}-standalone-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Associates this NSG to the NIC of your standlone VM
resource "azurerm_network_interface_security_group_association" "main" {
  network_interface_id      = azurerm_network_interface.standalone.id
  network_security_group_id = azurerm_network_security_group.main.id
}

resource "azurerm_windows_virtual_machine" "standalone" {
  name                = "${var.prefix}-vm"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = "Standard_B1s"
  admin_username      = "adminuser"
  admin_password      = "Password1234!"
  network_interface_ids = [azurerm_network_interface.standalone.id]

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  identity {
    type = "SystemAssigned"
  }
}

# azure key vault with rbac enabled

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "main" {
  name                      = "${var.prefix}-keyvault-delete"
  location                  = azurerm_resource_group.rg.location
  resource_group_name       = azurerm_resource_group.rg.name
  tenant_id                 = data.azurerm_client_config.current.tenant_id
  sku_name                  = "standard"
  soft_delete_retention_days = 7
  enable_rbac_authorization = true
}

resource "azurerm_role_assignment" "keyvault_admin" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

#storage account

resource "azurerm_storage_account" "main" {
  name                     = "${var.prefix}testacct"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "GRS"

  tags = {
    environment = "storm"
  }
}


# User assigned identity
resource "azurerm_user_assigned_identity" "example" {
  location            = azurerm_resource_group.rg.location
  name                = "${var.prefix}-userassignedidentity"
  resource_group_name = azurerm_resource_group.rg.name
}

# azure windows vm attached to virtual machine scale set with NSG
resource "azurerm_orchestrated_virtual_machine_scale_set" "main" {
  name                = "${var.prefix}-vmss-flex"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  platform_fault_domain_count = 1
}

resource "azurerm_windows_virtual_machine" "vmss_vm" {
  name                         = "${var.prefix}-vmss-vm"
  location                     = azurerm_resource_group.rg.location
  resource_group_name          = azurerm_resource_group.rg.name
  size                         = "Standard_B1s"
  admin_username               = "adminuser"
  admin_password               = "Password1234!"
  virtual_machine_scale_set_id = azurerm_orchestrated_virtual_machine_scale_set.main.id
  network_interface_ids        = [azurerm_network_interface.vmss.id]

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  identity {
    type = "SystemAssigned"
  }
}

# NIC for the VMSS
resource "azurerm_network_interface" "vmss" {
  name                = "${var.prefix}-vmss-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Associates the NSG to the NIC of the VMSS virtual machine
resource "azurerm_network_interface_security_group_association" "vmss" {
  network_interface_id      = azurerm_network_interface.vmss.id
  network_security_group_id = azurerm_network_security_group.main.id
}

 # creates the entra id user
resource "azuread_user" "main" {
  user_principal_name = "stormuser@earkevin11gmail088.onmicrosoft.com"
  display_name        = "Storm User"
  mail_nickname       = "stormuser"
  password            = "Password1234!"
  force_password_change = true
}



# fetch the built in azure ad role you want to assign
resource "azuread_directory_role" "main" {
  display_name = "Security Administrator"
}

# assign the role to the user
resource "azuread_directory_role_assignment" "main" {
  role_id             = azuread_directory_role.main.template_id
  principal_object_id = azuread_user.main.object_id
}


# create an Entra ID App registration

resource "azuread_application" "main" {
  display_name = "${var.prefix}-app-registration"
}