---
layout: post
title: 'Redfish Cheatsheet'
category: memo
slug: redfish-cheatsheet
---
## Redfish Data Model

All resources are linked from a service entry point (root), always located at URL `/redfish/v1`. Major resource types are structured in "collections" to allow for standalone, multi-node, or aggregated rack-level systems. And additional related resources fan out from members within these collections.

There are three main collections:

- ComputerSystem: properties expected from an OS console
    - Items needed to run the "computer"
    - Roughly a logical view of a computer system as seen from the OS
- Chassis: properties needed to locate the unit with your hands
    - Items needed to identify, install or service the "computer"
    - Roughly a physical view of a computer system as seen by human
- Managers: properties needed to perform administrative functions
    - AKA: the systems management subsystem (BMC)

## Authentication

### Simple Authentication

Just add `-u` with account and password arguments in each Redfish API request if you're using `curl`.

### Session-based Authentication

You must retrieve a token from the session service to do the operations you want later.

```bash
$ export bmc_ip="100.74.41.67"
$ curl -k -X POST -D headers.txt https://${bmc_ip}/redfish/v1/SessionService/Sessions -d '{"UserName": "ADMIN", "Password": "ADMIN"}'
{
	"@odata.context": "/redfish/v1/$metadata#Session.Session",
	"@odata.type": "#Session.v1_0_0.Session",
	"@odata.id": "/redfish/v1/SessionService/Sessions/1",
	"Id": "1",
	"Name": "User Session",
	"Description": "Manager User Session",
	"UserName": "ADMIN",
	"Oem": {}
}
$ cat headers.txt
HTTP/1.1 201 Created
Strict-Transport-Security: max-age=31536000; includeSubdomains
X-XSS-Protection: 1; mode=block
X-Frame-Options: SAMEORIGIN
X-Content-Type-Options: nosniff
OData-Version: 4.0
X-Auth-Token: d4ug1poq9btelo7ju2tqhyfko6xcqa0b
Location: /redfish/v1/SessionService/Sessions/1
Content-Length: 246
Content-Type: application/json
Date: Fri, 27 Dec 2019 05:06:45 GMT

$ export bmc_token="kuqk6u4n6hv1hwzifxswsb104qv6mnnc"
```

Also there is a way to remove the session we've just established, this is so called "logout":

```bash
$ curl -k -H "X-Auth-Token: ${bmc_token}" -X DELETE https://${bmc_ip}/redfish/v1/SessionService/Sessions/1
{"Success":{"code":"Base.v1_4_0.Success","Message":"Successfully Completed Request."}}
```

## Normal Get Operations

```bash
$ curl -k -H "X-Auth-Token: ${bmc_token}" -X GET https://${bmc_ip}/redfish/v1/Systems/1
{
	"@odata.context": "/redfish/v1/$metadata#ComputerSystem.ComputerSystem",
	"@odata.type": "#ComputerSystem.v1_3_1.ComputerSystem",
	"@odata.id": "/redfish/v1/Systems/1",
	"Id": "1",
	"Name": "System",
	"Description": "Description of server",
	"Status": {
		"State": "Enabled",
		"Health": "Critical"
	},
	"SerialNumber": "A298389X9B10165",
	"PartNumber": "SYS-2029GP-TR",
	"SystemType": "Physical",
	"BiosVersion": "3.1a",
	"Manufacturer": "Supermicro",
	"Model": "SYS-2029GP-TR",
	"SKU": "099515D9",
	"UUID": "009C065C-4200-EA11-8000-AC1F6BBC6E02",
	"ProcessorSummary": {
		"Count": 2,
		"Model": "Intel(R) Xeon(R) processor",
		"Status": {
			"State": "Enabled",
			"Health": "Critical"
		}
	},
	"MemorySummary": {
		"TotalSystemMemoryGiB": 768,
		"Status": {
			"State": "Enabled",
			"Health": "Critical"
		}
	},
	"IndicatorLED": "Off",
	"PowerState": "On",
	"Boot": {
		"BootSourceOverrideEnabled": "Disabled",
		"BootSourceOverrideMode": "Legacy",
		"BootSourceOverrideTarget": "None",
		"BootSourceOverrideTarget@Redfish.AllowableValues": [
			"None",
			"Pxe",
			"Floppy",
			"Cd",
			"Usb",
			"Hdd",
			"BiosSetup"
		]
	},
	"Processors": {
		"@odata.id": "/redfish/v1/Systems/1/Processors"
	},
	"Memory": {
		"@odata.id": "/redfish/v1/Systems/1/Memory"
	},
	"EthernetInterfaces": {
		"@odata.id": "/redfish/v1/Systems/1/EthernetInterfaces"
	},
	"SimpleStorage": {
		"@odata.id": "/redfish/v1/Systems/1/SimpleStorage"
	},
	"Storage": {
		"@odata.id": "/redfish/v1/Systems/1/Storage"
	},
	"LogServices": {
		"@odata.id": "/redfish/v1/Systems/1/LogServices"
	},
	"SecureBoot": {
		"@odata.id": "/redfish/v1/Systems/1/SecureBoot"
	},
	"PCIeDevices": [
		{
			"@odata.id": "/redfish/v1/Systems/1/PCIeDevices/NIC1"
		},
		{
			"@odata.id": "/redfish/v1/Systems/1/PCIeDevices/NIC2"
		},
		{
			"@odata.id": "/redfish/v1/Systems/1/PCIeDevices/NIC3"
		},
		{
			"@odata.id": "/redfish/v1/Systems/1/PCIeDevices/NIC4"
		},
		{
			"@odata.id": "/redfish/v1/Systems/1/PCIeDevices/GPU1"
		},
		{
			"@odata.id": "/redfish/v1/Systems/1/PCIeDevices/GPU2"
		},
		{
			"@odata.id": "/redfish/v1/Systems/1/PCIeDevices/GPU3"
		},
		{
			"@odata.id": "/redfish/v1/Systems/1/PCIeDevices/GPU4"
		}
	],
	"PCIeFunctions": [
		{
			"@odata.id": "/redfish/v1/Systems/1/PCIeDevices/NIC2/Functions/1"
		},
		{
			"@odata.id": "/redfish/v1/Systems/1/PCIeDevices/NIC2/Functions/2"
		},
		{
			"@odata.id": "/redfish/v1/Systems/1/PCIeDevices/NIC3/Functions/1"
		},
		{
			"@odata.id": "/redfish/v1/Systems/1/PCIeDevices/NIC3/Functions/2"
		},
		{
			"@odata.id": "/redfish/v1/Systems/1/PCIeDevices/NIC4/Functions/1"
		},
		{
			"@odata.id": "/redfish/v1/Systems/1/PCIeDevices/NIC4/Functions/2"
		},
		{
			"@odata.id": "/redfish/v1/Systems/1/PCIeDevices/GPU1/Functions/1"
		},
		{
			"@odata.id": "/redfish/v1/Systems/1/PCIeDevices/GPU2/Functions/1"
		},
		{
			"@odata.id": "/redfish/v1/Systems/1/PCIeDevices/GPU3/Functions/1"
		},
		{
			"@odata.id": "/redfish/v1/Systems/1/PCIeDevices/GPU4/Functions/1"
		}
	],
	"Links": {
		"Chassis": [
			{
				"@odata.id": "/redfish/v1/Chassis/1"
			}
		],
		"ManagedBy": [
			{
				"@odata.id": "/redfish/v1/Managers/1"
			}
		],
		"Oem": {}
	},
	"Actions": {
		"Oem": {},
		"#ComputerSystem.Reset": {
			"target": "/redfish/v1/Systems/1/Actions/ComputerSystem.Reset",
			"@Redfish.ActionInfo": "/redfish/v1/Systems/1/ResetActionInfo"
		}
	},
	"Oem": {
		"Supermicro": {
			"@odata.type": "#SmcSystemExtensions.v1_0_0.System",
			"SmcNodeManager": {
				"@odata.id": "/redfish/v1/Systems/1/SmcNodeManager"
			}
		}
	}
}
```

## Event Service

The event service is a new alert mechanism for Redfish. This alert will be sent out through HTTP or HTTPS to a web service that is subscribed to the service.
