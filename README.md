# steal

`check_cpu_steal` checks Linux VDS/VPS CPU steal over SSH. It helps detect whether a VM is being slowed down by host-node CPU contention or overselling.

The script uses normal `ssh`: keys, `ssh-agent`, `~/.ssh/config`, and password login work the same way as with manual SSH.

## Install

Debian/Ubuntu/Linux and macOS:

```bash
sh -c 'sha=$(curl -fsSL https://api.github.com/repos/Coloded/steal/commits/main | sed -n "s/.*\"sha\": \"\([0-9a-f]*\)\".*/\1/p" | head -1); curl -fsSL "https://raw.githubusercontent.com/Coloded/steal/$sha/install.sh" | bash'
```

The installer asks where to install:

```text
Install for all users with sudo? [y/N]:
```

Press Enter or answer `n` for a personal install without password:

```text
~/.local/bin/check_cpu_steal
```

Answer `y` to install for all users into the detected system directory; that path may ask for your sudo password. If the personal directory is not in `PATH`, the installer prints the line to add to your shell profile.
If `/usr/local/bin` exists but is not a directory, the installer falls back to personal install without sudo.

The public install command is permanent: it asks GitHub API for the current `main` commit SHA and downloads `install.sh` by that SHA, so GitHub raw CDN cache cannot install an older file.

## Install Directories

The installer detects the local Unix-like system and chooses install directories like this:

```text
System                    Personal install           All-users install
macOS                     ~/.local/bin               /opt/homebrew/bin, /usr/local/bin, /opt/local/bin
Debian                    ~/.local/bin               /usr/local/bin
Ubuntu                    ~/.local/bin               /usr/local/bin
Fedora                    ~/.local/bin               /usr/local/bin
RHEL/CentOS/Rocky/Alma    ~/.local/bin               /usr/local/bin
Arch/Manjaro              ~/.local/bin               /usr/local/bin
openSUSE/SLES             ~/.local/bin               /usr/local/bin
Alpine                    ~/.local/bin               /usr/local/bin
FreeBSD/OpenBSD/NetBSD    ~/bin                      /usr/local/bin
Solaris/illumos           ~/bin                      /opt/local/bin, /usr/local/bin
AIX/HP-UX                 ~/bin                      /usr/local/bin, /opt/freeware/bin, /opt/local/bin
```

For all-users install, the first existing directory from the list is used. Personal install never uses sudo.

Install into another user-writable directory:

```bash
sh -c 'sha=$(curl -fsSL https://api.github.com/repos/Coloded/steal/commits/main | sed -n "s/.*\"sha\": \"\([0-9a-f]*\)\".*/\1/p" | head -1); curl -fsSL "https://raw.githubusercontent.com/Coloded/steal/$sha/install.sh" | INSTALL_DIR="$HOME/.local/bin" bash'
```

Russian installer output:

```bash
sh -c 'sha=$(curl -fsSL https://api.github.com/repos/Coloded/steal/commits/main | sed -n "s/.*\"sha\": \"\([0-9a-f]*\)\".*/\1/p" | head -1); curl -fsSL "https://raw.githubusercontent.com/Coloded/steal/$sha/install.sh" | bash -s -- -ru'
```

## Usage

```bash
check_cpu_steal root@1.2.3.4
check_cpu_steal root@server.example.com -p 2222 -s 60
check_cpu_steal root@server.example.com --stress
check_cpu_steal root@server.example.com --no-stress
check_cpu_steal root@server.example.com -ru
check_cpu_steal root@server.example.com -j
check_cpu_steal --version
check_cpu_steal --update
```

By default `--stress-auto` is enabled: if CPU idle is above 50%, the script starts a random-number CPU generator on all detected vCPUs, measures steal, and stops the load before exit.

Use `-ru` or `--ru` for Russian output.
Use `-j` or `--json` for script-friendly JSON output.

JSON example:

```bash
check_cpu_steal root@server.example.com -s 30 -j
```

Example fields:

```json
{
  "host": "server.example.com",
  "vcpus": 4,
  "stress_mode": "auto",
  "stress_started": true,
  "samples": 30,
  "steal_average_percent": 0.53,
  "steal_max_1s_percent": 1.25,
  "grade": "Excellent"
}
```

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
