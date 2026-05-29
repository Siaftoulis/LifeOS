package main

import (
	"encoding/json"
	"fmt"
	"os/exec"
	"regexp"
)

// sanitizeName ensures the VM name only contains safe characters to prevent injection
func sanitizeName(name string) error {
	matched, _ := regexp.MatchString(`^[a-zA-Z0-9_-]+$`, name)
	if !matched || name == "" {
		return fmt.Errorf("invalid or unsafe VM name provided")
	}
	return nil
}

// executePowerShell runs a command securely via PowerShell
func executePowerShell(command string) (string, error) {
	cmd := exec.Command("powershell.exe", "-NoProfile", "-NonInteractive", "-Command", command)
	out, err := cmd.CombinedOutput()
	if err != nil {
		return "", fmt.Errorf("PowerShell Error: %s | %v", string(out), err)
	}
	return string(out), nil
}

// StartVM executes the Hyper-V Start-VM cmdlet
func StartVM(vmName string) (string, error) {
	if err := sanitizeName(vmName); err != nil {
		return "", err
	}
	return executePowerShell(fmt.Sprintf("Start-VM -Name '%s'", vmName))
}

// StopVM executes the Hyper-V Stop-VM cmdlet
func StopVM(vmName string) (string, error) {
	if err := sanitizeName(vmName); err != nil {
		return "", err
	}
	return executePowerShell(fmt.Sprintf("Stop-VM -Name '%s' -Force", vmName))
}

// GetVirtualMachines executes Get-VM and parses the JSON output
func GetVirtualMachines() ([]VMInfo, error) {
	out, err := executePowerShell(`@(Get-VM) | Select-Object Name, State | ConvertTo-Json -Compress`)
	if err != nil {
		return nil, err
	}
	if out == "" || out == "null" {
		return []VMInfo{}, nil
	}
	var vms []VMInfo
	if err := json.Unmarshal([]byte(out), &vms); err != nil {
		return nil, fmt.Errorf("failed to parse VM JSON: %v", err)
	}
	return vms, nil
}
