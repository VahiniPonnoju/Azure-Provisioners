resource "azurerm_resource_group" "RG" {
  name     = "TFDemo"
  location = "East US"
}
resource "azurerm_virtual_network" "vnet" {
  name                = "rg-network"
  address_space       = ["10.100.0.0/16"]
  location            = azurerm_resource_group.RG.location
  resource_group_name = azurerm_resource_group.RG.name
}
resource "azurerm_subnet" "rg_subnet" {
  name                 = "internal"
  address_prefixes     = ["10.100.1.0/24"]
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.RG.name

}
resource "azurerm_network_interface" "nic" {
  count               = 3
  name                = "${var.nic}-${count.index}"
  resource_group_name = azurerm_resource_group.RG.name
  location            = azurerm_resource_group.RG.location
  ip_configuration {
    name                          = "internal-${count.index}"
    subnet_id                     = azurerm_subnet.rg_subnet.id
    private_ip_address_allocation = "Dynamic"

  }
}
resource "azurerm_virtual_machine" "vm" {
  count                            = 3
  name                             = "${var.vm_name}-${count.index}"
  resource_group_name              = azurerm_resource_group.RG.name
  location                         = azurerm_resource_group.RG.location
  vm_size                          = "standard_DS1_v2"
  network_interface_ids            = [azurerm_network_interface.nic[count.index].id]
  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "canonical"
    offer     = "ubuntuserver"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk-${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "hostname-${count.index}"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }

}