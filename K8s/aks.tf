resource "azurerm_public_ip" "ingress_ip" {
  name                = "vhg-ingress-ip"
  location            = local.location
  resource_group_name = data.azurerm_resource_group.existing_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = "vhg-garden-dharshan"
}