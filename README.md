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

## Continuous Integration

This project includes automated GitHub Actions CI that builds the tweak on every push and pull request to the `main`/`master` branches. The workflow:

- Runs on a macOS runner with Theos configured for iOS 16.5 SDK
- Uses rootless packaging (`THEOS_PACKAGE_SCHEME=rootless`) with the target `iphone:clang:latest:16.5`
- Caches Theos toolchain and SDK to speed up subsequent builds
- Produces a release `.deb` package and uploads it as a workflow artifact

See `.github/workflows/build.yml` for the full workflow definition.

> **Note**
> This project now includes a Preferences bundle (`com.wechat.keyboardswitch`) that can be configured in Settings.
