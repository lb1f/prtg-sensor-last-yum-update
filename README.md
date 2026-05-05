# Yum Security Update Sensor

Lightweight shell sensors for RHEL-family Linux servers, reporting
either the count of outstanding security advisories or the number of
days since the last package update. Output uses the
`returncode:value:message` format consumed by SSH-script-based
monitoring tools.

## Compatibility

Tested on RHEL, AlmaLinux, Rocky, and Amazon Linux. The security
update script uses `yum updateinfo`, which is available on all of
these out of the box (no third-party package required).

The original CentOS 6/7 era version of the security script depended
on `centos-package-cron`; that dependency has been dropped.

## Scripts

- **`yum-outstanding-security-updates-check.sh`** — Counts distinct
  outstanding security advisories (Critical / Important / Moderate).
  Counts advisories rather than packages so that, e.g., a kernel
  update reports as one item rather than six.
- **`yum-last-update-check.sh`** — Reports days since the last
  successful `yum` transaction.

Both write a single `returncode:value:message` line to stdout.

## Installation

1. Copy the chosen script to a directory on the target server, e.g.
   `/var/prtg/scripts/`.
2. `chmod +x` the script.
3. Configure your monitoring tool to invoke it over SSH and parse the
   output line.

The security update script caches its result in `/tmp/lastyumcheck`
and only re-runs `yum updateinfo` when the cached date is older than
the current day, so it is safe to poll frequently.

## Applying the updates this reports

```sh
# All severities
yum update --security

# Just one severity
yum update --sec-severity=Important

# Specific severities
yum update --sec-severity=Critical --sec-severity=Important
```

The detailed advisory list (CVEs, references, package sets) is
written to `/tmp/security-update-detail` on each refresh — read this
before approving a maintenance window.

## Output format

```
0:7:7 Outstanding Security Updates
^ ^ ^
| | └─ Human-readable message
| └─── Numeric value (the count)
└───── Return code: 0=OK, 1=Warning, 2=System Error, 3=Protocol, 4=Content
```
