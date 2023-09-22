# Overview
This repo is just storing a repro for an issue in the AADSSHLoginforLinux so that it's more easily shareable.

The issue is that when we try to create a VMSS using the `cbl-mariner-2-gen2` image SKU with the AADSSHLoginforLinux extension enabled, we hit a race condition and the creation fails with this error:

```
The handler for VM extension type 'Microsoft.Azure.ActiveDirectory.AADSSHLoginForLinux' has reported terminal failure for VM extension 'AADSSHLoginForLinux' with error message: '[ExtensionOperationError] Non-zero exit code: 51, /var/lib/waagent/Microsoft.Azure.ActiveDirectory.AADSSHLoginForLinux-1.0.2385.1/./installer.sh install
[stdout]
Machine OS: mariner v2.0 x86_64
Installing...
waiting for tdnf_instance lock on /var/run/.tdnf-instance-lockfile
This is an Azure machine
Configuring microsoft-prod repo


[stderr]
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
100    15  100    15    0     0    923      0 --:--:-- --:--:-- --:--:--   937
Unsupported Linux version. Learn more at https://aka.ms/AADSSHLogin'.

'Install handler failed for the extension. More information on troubleshooting is available at https://aka.ms/vmextensionlinuxtroubleshoot' (Code:VMExtensionHandlerNonTransientError)
```

# Steps to repro
To repro the issue, do the following:

1. Create a resource group
2. Generate an admin password which is sufficiently complex
3. Run the following:
    ```powershell
    $password = ConvertTo-SecureString -String "{PASSWORD}" -AsPlainText
    ./deploy.ps1 -ResourceGroup "{RESOURCE_GROUP_NAME}" -Password $password
    ```


# Workaround

If I add a "sleep" while installing extensions, like below, then the issue is avoided (so this seems to work as a workaround, but it's just hiding the real issue):

```json
{
    "type": "Microsoft.Compute/virtualMachineScaleSets/extensions",
    "name": "Wait60Seconds",
    "properties": {
        "publisher": "Microsoft.Azure.Extensions",
        "type": "CustomScript",
        "typeHandlerVersion": "2.0",
        "autoUpgradeMinorVersion": true,
        "settings": {
            "commandToExecute": "sleep 60"
        }
    }
},
{
    "name": "AADSSHLoginForLinux",
    "properties": {
        "provisionAfterExtensions": [
            "Wait60Seconds"
        ],
        "settings": {},
        "autoUpgradeMinorVersion": true,
        "publisher": "Microsoft.Azure.ActiveDirectory",
        "type": "AADSSHLoginForLinux",
        "typeHandlerVersion": "1.0"
    }
}
```

