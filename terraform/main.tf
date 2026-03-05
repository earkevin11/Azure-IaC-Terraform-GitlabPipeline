# heart of the configuration. It defines the actual infrastructure resources you want to create 
# (resource groups, VMs, storage accounts, etc.)

resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}-ResourceGroup"
  location = var.location

  tags = {
    environment = "storm"
  }

  depends_on = [azurerm_subscription_policy_assignment.allowed_resources]  # 👈 This forces Terraform to deploy the policy first, then the resource group, then everything else that depends on the resource group.
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


# ── WINDOWS 2022 NIC ────────────────────────────────────────────────────────
resource "azurerm_network_interface" "windows2022_nic" {
  name                = "${var.prefix}-windows2022-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id        # ← your existing subnet
    private_ip_address_allocation = "Dynamic"
  }
}

# ── ASSOCIATE EXISTING NSG TO NEW NIC ───────────────────────────────────────
resource "azurerm_network_interface_security_group_association" "windows2022_nsg" {
  network_interface_id      = azurerm_network_interface.windows2022_nic.id
  network_security_group_id = azurerm_network_security_group.main.id  # ← your existing NSG
}

# ── WINDOWS SERVER 2022 VM ───────────────────────────────────────────────────
resource "azurerm_windows_virtual_machine" "windows2022" {
  name                  = "${var.prefix}-2022vm"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  size                  = "Standard_B1s"
  admin_username        = "adminuser"
  admin_password        = "Password1234!"
  network_interface_ids = [azurerm_network_interface.windows2022_nic.id]

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    environment = "test"
    os          = "windows2022"
  }
}

# ── NETWORK INTERFACE ───────────────────────────────────────────────────────
resource "azurerm_network_interface" "trustedlaunch_nic" {
  name                = "${var.prefix}-tl-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
  }
}

# ── NSG ASSOCIATION ─────────────────────────────────────────────────────────
resource "azurerm_network_interface_security_group_association" "trustedlaunch_nsg" {
  network_interface_id      = azurerm_network_interface.trustedlaunch_nic.id
  network_security_group_id = azurerm_network_security_group.main.id
}

# ── TRUSTED LAUNCH WINDOWS SERVER 2022 VM ───────────────────────────────────
resource "azurerm_windows_virtual_machine" "trustedlaunch_vm" {
  name                  = "${var.prefix}-tl-vm"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  size                  = "Standard_B2s"       # must be a Gen2 supported size
  admin_username        = "adminuser"
  admin_password        = "Password1234!"
  network_interface_ids = [azurerm_network_interface.trustedlaunch_nic.id]

  # ── Trusted Launch requires a Gen2 image ──────────────────────────────────
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"  # Gen2 + Trusted Launch capable
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  # ── Trusted Launch settings ───────────────────────────────────────────────
  vtpm_enabled        = true   # virtual TPM
  secure_boot_enabled = true   # Secure Boot

  identity {
    type = "SystemAssigned"
  }

  tags = {
    environment = "test"
    os          = "windows2022-trusted-launch"
  }
}

# ── NETWORK INTERFACE ───────────────────────────────────────────────────────
resource "azurerm_network_interface" "tl2_nic" {
  name                = "${var.prefix}-tl2-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_security_group_association" "tl2_nsg" {
  network_interface_id      = azurerm_network_interface.tl2_nic.id
  network_security_group_id = azurerm_network_security_group.main.id
}

resource "azurerm_windows_virtual_machine" "tl2_vm" {
  name                  = "${var.prefix}-tl2-vm"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  size                  = "Standard_B2s"
  admin_username        = "adminuser"
  admin_password        = "Password1234!"
  network_interface_ids = [azurerm_network_interface.tl2_nic.id]

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-datacenter-gensecond"   # Windows Server 2019 Gen2
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  vtpm_enabled        = true
  secure_boot_enabled = true

  identity {
    type = "SystemAssigned"
  }

  tags = {
    environment = "test"
    os          = "windows2019-gen2-trusted-launch"
  }
}

# ── NETWORK INTERFACE ───────────────────────────────────────────────────────
resource "azurerm_network_interface" "tl3_nic" {
  name                = "${var.prefix}-tl3-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_security_group_association" "tl3_nsg" {
  network_interface_id      = azurerm_network_interface.tl3_nic.id
  network_security_group_id = azurerm_network_security_group.main.id
}

resource "azurerm_windows_virtual_machine" "tl3_vm" {
  name                  = "${var.prefix}-tl3-vm"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  size                  = "Standard_B2s"
  admin_username        = "adminuser"
  admin_password        = "Password1234!"
  network_interface_ids = [azurerm_network_interface.tl3_nic.id]

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2025-datacenter-azure-edition"  # Windows Server 2025 Gen2
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  vtpm_enabled        = true
  secure_boot_enabled = true
  patch_mode = "AutomaticByPlatform"

  identity {
    type = "SystemAssigned"
  }

  tags = {
    environment = "test"
    os          = "windows2025-trusted-launch"
  }
}



# ── NSG ASSOCIATION ─────────────────────────────────────────────────────────
resource "azurerm_network_interface_security_group_association" "public_ip_nsg" {
  network_interface_id      = azurerm_network_interface.publicNIC.id
  network_security_group_id = azurerm_network_security_group.main.id
}

# ── PUBLIC IP ───────────────────────────────────────────────────────────────
resource "azurerm_public_ip" "publicip" {
  name                = "${var.prefix}-public-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# ── NIC (with public IP attached) ───────────────────────────────────────────
resource "azurerm_network_interface" "publicNIC" {
  name                = "${var.prefix}-public-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.publicip.id  # 👈 this is the key line
  }
}

# ── VM ───────────────────────────────────────────────────────────────────────
resource "azurerm_windows_virtual_machine" "publicvm" {
  name                  = "${var.prefix}-publicvm"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  size                  = "Standard_B1s"
  admin_username        = "adminuser"
  admin_password        = "Password1234!"
  network_interface_ids = [azurerm_network_interface.publicNIC.id]

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-datacenter-gensecond" # supports Trusted Launch
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  vtpm_enabled        = true
  secure_boot_enabled = true
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

# Reads your current subscription info based on your gitlab variables 

data "azurerm_subscription" "primary" {}

# Assign the owner role to user
resource "azurerm_role_assignment" "subscription_owner" {
  scope  = data.azurerm_subscription.primary.id
  role_definition_name = "Owner"
  principal_id = azuread_user.main.object_id
}


# create an Entra ID App registration

resource "azuread_application" "main" {
  display_name = "${var.prefix}-app-registration"
}

# create a azure sql server

resource "azurerm_mssql_server" "sqlserver" {
  name                         = "${var.prefix}-sql-server-test"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = "westus"
  version                      = "12.0"
  administrator_login          = "missadministrator"
  administrator_login_password = "thisIsKat11"
  minimum_tls_version          = "1.2"

  tags = {
    environment = "test"
  }
}