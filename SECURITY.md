# Security Policy

## Supported versions

Only the latest release of Amazing Pet receives security fixes.

## Reporting a vulnerability

Please **do not open a public issue** for security problems.

Report it privately through GitHub instead: open the [**Security** tab](../../security) of this repository and click **Report a vulnerability**. Include the steps to reproduce, the affected version and the impact you expect.

You can expect an acknowledgement within a week. Once the issue is confirmed, a fix is released and the reporter is credited unless they prefer otherwise.

## What Amazing Pet does and does not access

- No network access, analytics or telemetry.
- It reads CPU, memory, thermal, battery and idle-time statistics locally.
- During screen play it reads only the **frames** of on-screen windows (position and size) through `CGWindowList`. It never reads window titles or contents, and it needs no Screen Recording permission.
- Settings are stored in the app's own `UserDefaults` domain.

## Release integrity

Every release ships a `SHA256SUMS.txt`. Verify a download with:

```sh
shasum -a 256 -c SHA256SUMS.txt --ignore-missing
```

Releases are built only by the GitHub Actions workflow in this repository. Third-party actions are not used, and the one first-party action is pinned to a full commit SHA.
