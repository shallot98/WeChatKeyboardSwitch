# WeChatKeyboardSwitch

Rootless Theos tweak skeleton targeting WeChat (`com.tencent.xin`). Currently this project is a scaffold with no functional hooks.

## Requirements

- [Theos](https://theos.dev/) environment configured with the latest iOS 16.5 SDK
- Rootless packaging support (`THEOS_PACKAGE_SCHEME = rootless`)

## Building

```bash
make package
```

The generated rootless `.deb` will be placed inside the `packages/` directory.

## Installing

Use `ssh` or `sftp` to copy the generated package to your jailbroken device and install via `sileo`, `zebra`, or `dpkg` (for rootless setups use `ldid` / `dpkg` inside your rootless shell).

Example (assuming `THEOS_DEVICE_IP` is set):

```bash
make install
```

> **Note**
> This project now includes a Preferences bundle (`com.wechat.keyboardswitch`) that can be configured in Settings.
