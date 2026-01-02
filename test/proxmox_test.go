package test

import (
	"fmt"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/retry"
	"github.com/gruntwork-io/terratest/modules/ssh"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

var terraformOptions *terraform.Options

// TestMain runs setup and teardown for all tests
func TestMain(m *testing.M) {
	terraformOptions = terraform.WithDefaultRetryableErrors(&testing.T{}, &terraform.Options{
		TerraformDir: "../",
		NoColor:      true,
		Reconfigure:  true,
	})

	// Run "terraform init" and "terraform apply"
	terraform.InitAndApply(&testing.T{}, terraformOptions)

	// Run all tests
	exitCode := m.Run()

	// Teardown: Clean up resources with "terraform destroy"
	terraform.Destroy(&testing.T{}, terraformOptions)

	// Exit with the test result code
	os.Exit(exitCode)
}

func TestSSHAccess(t *testing.T) {
	// find the VM IP address from the output
	var IPOutput [][]string
	terraform.OutputStruct(t, terraformOptions, "debian_vm_ip_addresses", &IPOutput)
	var vmIP string
outer:
	for _, ips := range IPOutput {
		for _, ip := range ips {
			if ip != "127.0.0.1" && ip != "::1" {
				vmIP = ip
				break outer
			}
		}
	}
	if vmIP == "" {
		t.Fatal("No valid IP address found for the VM")
	}

	// get the SSH private key from the output
	sshPrivateKey := terraform.Output(t, terraformOptions, "debian_vm_private_key")
	sshPublicKey := terraform.Output(t, terraformOptions, "debian_vm_public_key")
	sshKeyPair := ssh.KeyPair{
		PrivateKey: sshPrivateKey,
		PublicKey:  sshPublicKey,
	}

	vmHost := ssh.Host{
		Hostname:    vmIP,
		SshUserName: "debian",
		SshKeyPair:  &sshKeyPair,
	}

	// It can take a minute or so for the Instance to boot up, so retry a few times
	maxRetries := 30
	timeBetweenRetries := 5 * time.Second
	description := fmt.Sprintf("SSH to public host %s", vmIP)

	// Run a simple echo command on the server
	expectedText := "Hello, World"
	command := fmt.Sprintf("echo -n '%s'", expectedText)

	// Verify that we can SSH to the Instance and run commands
	retry.DoWithRetry(t, description, maxRetries, timeBetweenRetries, func() (string, error) {
		actualText, err := ssh.CheckSshCommandE(t, vmHost, command)
		if err != nil {
			return "", err
		}

		if strings.TrimSpace(actualText) != expectedText {
			return "", fmt.Errorf("Expected SSH command to return '%s' but got '%s'", expectedText, actualText)
		}

		return "", nil
	})

	expectedText = "Hello, World"
	command = fmt.Sprintf("echo -n '%s' && exit 1", expectedText)
	description = fmt.Sprintf("SSH to public host %s with error command", vmIP)

	// Now test something that returns an error code.
	retry.DoWithRetry(t, description, maxRetries, timeBetweenRetries, func() (string, error) {
		actualText, err := ssh.CheckSshCommandE(t, vmHost, command)
		if err == nil {
			return "", fmt.Errorf("Expected SSH command to return an error but got none")
		}

		if strings.TrimSpace(actualText) != expectedText {
			return "", fmt.Errorf("Expected SSH command to return '%s' but got '%s'", expectedText, actualText)
		}

		return "", nil
	})
}
