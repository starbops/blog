---
layout: post
title: 'iDRAC Lifecycle Controller'
category: note
slug: idrac-lifecycle-controller
---
## Lifecycle Controller in Recovery Mode

Because disk space is not enough on `pve1`, I'm planning to use 4 unused HDDs in
the chassis using iDRAC's build RAID on-the-fly feature. However, it told me the
job cannot be done due to lifecycle controller issue. The lifecycle controller
is in recovery mode, not enabled. So I had to reboot the server.

## How to Solve This

```text
racadm>>get LifecycleController.LCAttributes.LifecycleControllerState

racadm get LifecycleController.LCAttributes.LifecycleControllerState
Recovery

racadm>>set LifecycleController.LCAttributes.LifecycleControllerState 0

racadm set LifecycleController.LCAttributes.LifecycleControllerState 0
Object value modified successfully

racadm>>get LifecycleController.LCAttributes.LifecycleControllerState

racadm get LifecycleController.LCAttributes.LifecycleControllerState
Disabled

racadm>>set LifecycleController.LCAttributes.LifecycleControllerState 1

racadm set LifecycleController.LCAttributes.LifecycleControllerState 1
Object value modified successfully

racadm>>get LifecycleController.LCAttributes.LifecycleControllerState

racadm get LifecycleController.LCAttributes.LifecycleControllerState
Enabled
```

## References

-  [Lifecycle Controller is in Recovery Mode and is disabled](https://www.dell.com/community/PowerEdge-Hardware-General/Lifecycle-Controller-is-in-Recovery-Mode-and-is-disabled/td-p/7342571)
