
	terraform {
	  required_providers {
	    azurerm = {
	      source  = "hashicorp/azurerm"
	      version = "~> 4.0"
	    }
	  }
	}
	
	provider "azurerm" {
	  features {}
	  # Authentication is handled via environment variables or Azure CLI.
	  # Ensure you are logged in with 'az login' before running tests if environment variables are not set.
	}
	