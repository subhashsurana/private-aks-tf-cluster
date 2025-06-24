# Terratest Setup Guide for Private AKS Terraform Cluster

This guide explains how to set up and use Terratest to test your Terraform modules in this repository.

## Prerequisites

- Go 1.16 or later
- Terraform installed
- Azure CLI installed and configured with appropriate permissions
- Azure subscription with permissions to create resources

## Setup

Terratest is already configured in this repository. The main components are:

1. **Go modules**: Each module that needs testing has its own `go.mod` file with Terratest dependencies.
2. **Test files**: Test files are named with the `_test.go` suffix and are located in the same directory as the module.

## Understanding the Test Structure

The test file `core_test.go` demonstrates how to test the core module:

```go
package test

import (
	"fmt"
	"testing"

	"github.com/gruntwork-io/terratest/modules/azure"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestCoreModule(t *testing.T) {
	t.Parallel()

	// Generate a random prefix to prevent naming conflicts
	uniquePrefix := fmt.Sprintf("terratest-%s", random.UniqueId())
	
	// Configure Terraform options
	terraformOptions := &terraform.Options{
		TerraformDir: "../../stacks/core",
		Vars: map[string]interface{}{
			"prefix":   uniquePrefix,
			"location": "eastus",
		},
		EnvVars: map[string]string{
			"ARM_CLIENT_ID":       "", // Set these in your CI/CD pipeline or locally
			"ARM_CLIENT_SECRET":   "", // for testing, or use Azure CLI authentication
			"ARM_SUBSCRIPTION_ID": "",
			"ARM_TENANT_ID":       "",
		},
		NoColor: true,
	}

	// Clean up resources at the end of the test
	defer terraform.Destroy(t, terraformOptions)

	// Deploy the infrastructure
	terraform.InitAndApply(t, terraformOptions)

	// Validate the deployment
	vnetID := terraform.Output(t, terraformOptions, "vnet_id")
	subnetID := terraform.Output(t, terraformOptions, "subnet_aks_id")
	
	// Verify resources exist
	resourceGroupName := fmt.Sprintf("%s-core-rg", uniquePrefix)
	vnetName := fmt.Sprintf("%s-vnet", uniquePrefix)
	exists := azure.VirtualNetworkExists(t, vnetName, resourceGroupName, "")
	assert.True(t, exists, "Virtual network should exist")
	
	// Additional assertions
	// ...
}
```

## Key Components of a Terratest Test

1. **Test Function**: Each test is a Go function that starts with `Test` and takes a `*testing.T` parameter.

2. **Terraform Options**: Configure how Terraform should run:
   - `TerraformDir`: Path to the Terraform code
   - `Vars`: Variables to pass to Terraform
   - `EnvVars`: Environment variables for authentication
   - `NoColor`: Disable color output for easier parsing

3. **Resource Cleanup**: Use `defer terraform.Destroy(t, terraformOptions)` to clean up resources after the test.

4. **Deployment**: Use `terraform.InitAndApply(t, terraformOptions)` to deploy the infrastructure.

5. **Validation**: Use assertions to validate that the infrastructure was deployed correctly:
   - Check outputs with `terraform.Output()`
   - Verify resources exist with Azure-specific functions
   - Use `assert` functions to validate conditions

## Authentication

For Azure authentication, you have several options:

1. **Environment Variables**: Set the following environment variables:
   ```
   export ARM_CLIENT_ID="your-client-id"
   export ARM_CLIENT_SECRET="your-client-secret"
   export ARM_SUBSCRIPTION_ID="your-subscription-id"
   export ARM_TENANT_ID="your-tenant-id"
   ```

2. **Azure CLI**: If you're already logged in with the Azure CLI, Terratest can use that authentication.

3. **Service Principal**: Create a service principal and use its credentials:
   ```bash
   az ad sp create-for-rbac --name "terratest-sp" --role Contributor
   ```

## Running Tests

To run the tests, navigate to the module directory and use the `go test` command:

```bash
cd app/modules/core
go test -v
```

For more control over test execution:

```bash
# Run a specific test
go test -v -run TestCoreModule

# Set a timeout (tests can take a while to run)
go test -v -timeout 30m

# Skip long-running tests
go test -v -short
```

## Best Practices

1. **Use Unique Names**: Always use random suffixes for resource names to avoid conflicts.

2. **Clean Up Resources**: Always use `defer terraform.Destroy()` to clean up resources.

3. **Parallelize Tests**: Use `t.Parallel()` to run tests in parallel, but be careful with resource limits.

4. **Test Isolation**: Each test should be independent and not rely on resources created by other tests.

5. **Minimal Testing**: Test only what's necessary to validate your module's functionality.

6. **Use Assertions**: Use the `assert` package to make your test validations clear and readable.

7. **Handle Errors**: Check for errors and fail the test with clear messages.

## Adding Tests for New Modules

To add tests for a new module:

1. Create a new `go.mod` file in the module directory:
   ```bash
   cd app/modules/new-module
   go mod init github.com/subhashsurana/private-aks-tf-cluster/app/modules/new-module
   go get github.com/gruntwork-io/terratest@v0.50.0
   ```

2. Create a test file (e.g., `new_module_test.go`) with appropriate tests.

3. Run the tests as described above.

## Troubleshooting

- **Authentication Issues**: Ensure you have the correct permissions and credentials.
- **Resource Limits**: Azure subscriptions have resource limits that can cause tests to fail.
- **Timeouts**: Infrastructure tests can take a long time to run. Use appropriate timeouts.
- **Cleanup Failures**: If `terraform destroy` fails, resources may be left behind. Clean them up manually.

## Additional Resources

- [Terratest GitHub Repository](https://github.com/gruntwork-io/terratest)
- [Terratest Documentation](https://terratest.gruntwork.io/docs/)
- [Azure Terraform Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
