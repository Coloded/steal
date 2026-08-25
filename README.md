# steal

`check_cpu_steal` checks Linux VDS/VPS CPU steal over SSH. It helps detect whether a VM is being slowed down by host-node CPU contention or overselling.

The script uses normal `ssh`: keys, `ssh-agent`, `~/.ssh/config`, and password login work the same way as with manual SSH.

## Install

Debian/Ubuntu/Linux and macOS:

```bash
curl -fsSL https://raw.githubusercontent.com/Coloded/steal/main/install.sh | bash
```

The installer asks where to install:

```text
Install for all users with sudo? [y/N]:
```

Press Enter or answer `n` for a personal install without password:

```text
~/.local/bin/check_cpu_steal
```

Answer `y` to install for all users into `/usr/local/bin`; that path may ask for your sudo password. If `~/.local/bin` is not in `PATH`, the installer prints the line to add to your shell profile.

Install into another user-writable directory:

```bash
curl -fsSL https://raw.githubusercontent.com/Coloded/steal/main/install.sh | INSTALL_DIR="$HOME/.local/bin" bash
```

Russian installer output:

```bash
curl -fsSL https://raw.githubusercontent.com/Coloded/steal/main/install.sh | bash -s -- -ru
```

## Usage

```bash
check_cpu_steal root@1.2.3.4
check_cpu_steal root@server.example.com -p 2222 -s 60
check_cpu_steal root@server.example.com --stress
check_cpu_steal root@server.example.com --no-stress
check_cpu_steal root@server.example.com -ru
check_cpu_steal --version
check_cpu_steal --update
```

By default `--stress-auto` is enabled: if CPU idle is above 50%, the script starts a random-number CPU generator on all detected vCPUs, measures steal, and stops the load before exit.

Use `-ru` or `--ru` for Russian output.

## Update

```bash
check_cpu_steal --update
```

The update command downloads the latest script from GitHub, compares versions, and runs the installer only when a newer version is available. If you already have the latest version, it says so and exits.

## Grades

```text
<1%      Excellent: everything looks great
1-3%     Good: CPU steal is low
3-5%     OK: below 5%, usable
5-10%    Bad: noticeable CPU contention / likely overselling (bad)
10-20%   Very bad: the VM regularly does not receive CPU time (very bad)
20-30%   Terrible: serious performance degradation (terrible)
30-50%   Critical: the host node is heavily overloaded (the server is being throttled)
50-70%   Severe: the VM is CPU-starved most of the time (almost unusable)
70%+     Unusable: normal work is almost impossible (everything is bad)
```

## Russian

```bash
check_cpu_steal root@server.example.com -ru
check_cpu_steal --update -ru
```

With `-ru`, all `check_cpu_steal` output is in Russian.
