# steal

`check_cpu_steal` проверяет CPU steal на Linux VDS/VPS через SSH. Это помогает понять, не душит ли виртуалку перегруженная хост-нода или оверселл.

Скрипт использует обычный `ssh`: ключи, `ssh-agent`, `~/.ssh/config` и парольный вход работают так же, как при ручном подключении.

## Установка

Linux Debian/Ubuntu и macOS:

```bash
curl -fsSL https://raw.githubusercontent.com/Coloded/steal/main/install.sh | bash
```

Если `/usr/local/bin` требует пароль, installer попросит `sudo`.

Установка в другой каталог:

```bash
curl -fsSL https://raw.githubusercontent.com/Coloded/steal/main/install.sh | INSTALL_DIR="$HOME/.local/bin" bash
```

## Использование

```bash
check_cpu_steal root@1.2.3.4
check_cpu_steal root@server.example.com -p 2222 -s 60
check_cpu_steal root@server.example.com --stress
check_cpu_steal root@server.example.com --no-stress
```

По умолчанию включен `--stress-auto`: если CPU простаивает больше 50%, скрипт запускает генератор случайных чисел на все найденные vCPU, измеряет steal и останавливает нагрузку перед выходом.

## Градации

```text
<1%      Excellent: все отлично
1-3%     Good: все хорошо
3-5%     OK: до 5%, жить можно
5-10%    Bad: заметный CPU contention / вероятный оверселл (плохо)
10-20%   Very bad: VM регулярно не получает CPU (очень плохо)
20-30%   Terrible: сильная деградация производительности (ужасно)
30-50%   Critical: хост-нода сильно перегружена (сервер душат)
50-70%   Severe: VM большую часть времени CPU-starved (почти неработоспособно)
70%+     Unusable: нормально работать почти невозможно (все пропало)
```
