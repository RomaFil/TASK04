# TASK04 — hostinfo: збірка на HOST і TARGET

## 1. Мета і склад репозиторію
Програма `hostinfo.c` виводить hostname, час, ОС і архітектуру (`uname`, `time`)
та, якщо задано ім'я файлу аргументом, дописує вивід у файл (з попередженням,
якщо файл уже існує).

| Файл | Призначення |
|---|---|
| `hostinfo.c` | програма |
| `build_host.sh` | нативна динамічна збірка + тест + аналіз |
| `build_target.sh` | крос-збірка `aarch64-linux-gnu-gcc` |
| `build_static.sh` | збірка з `-static` |
| `analyze.sh` | аналіз binutils (file, readelf, ldd, size, objdump, strings) |
| `reports/` | сирі результати аналізу (`<бінарник>@<хост>.txt`) |

## 2. Середовище
| | HOST | TARGET |
|---|---|---|
| Машина | ПК, WSL2 (Ubuntu 26.04) | Raspberry Pi 5, 16 ГБ ОЗП |
| Ядро | 6.18.33.2-microsoft-standard-WSL2 | 6.18.50+rpt-rpi-2712 |
| ОС | Ubuntu 26.04 LTS | Debian GNU/Linux 13 (trixie), стоковий образ Raspberry Pi OS |
| Архітектура | x86_64 | aarch64 |
| gcc | 15.2.0 (Ubuntu 15.2.0-16ubuntu1) | 14.2.0 (Debian 14.2.0-19) |
| glibc | 2.43 (Ubuntu 26.04) | 2.41 (Debian 2.41-12+rpt1+deb13u4) |
| Часовий пояс у виводі | UTC | EEST |
| Крос-компілятор | `aarch64-linux-gnu-gcc` 15.2.0 (пакет `gcc-aarch64-linux-gnu`) | — |

У стоковому образі TARGET вже встановлені `gcc`, `git`, `make`, `file`, `readelf`,
`objdump`, `size`, `strings`, `ldd`, тобто середовище розробки на TARGET є ще до
виконання п. 4.

## 3. Крок 2 — нативна збірка на HOST
Команда: `gcc -std=c11 -Wall -Wextra -Werror -O2 hostinfo.c`.

**Перевірка працездатності:**
- вивід у консоль містить hostname, час, ОС, версію ядра, архітектуру — так;
- перший запуск з файлом створює його, другий виводить
  `WARNING: file 'build/t.txt' exists, appending` і дописує другий блок — так.

**Аналіз binutils** (`reports/hostinfo_native@Roman.txt`):
- ELF64 PIE, x86-64, динамічний; interpreter `/lib64/ld-linux-x86-64.so.2`
- залежність лише `libc.so.6`
- розмір 16 456 байт; `size`: text 3080, data 664, bss 48
- потрібні версії glibc: до `GLIBC_2.34`
- у `strings` є `__fprintf_chk` і `__stack_chk_fail`: Ubuntu вмикає
  FORTIFY_SOURCE і stack protector за замовчуванням

## 4. Крок 3 — крос-збірка HOST→TARGET
Команда: `aarch64-linux-gnu-gcc -std=c11 -Wall -Wextra -Werror -O2 hostinfo.c`
(`build_target.sh`). Бінарник перенесено на TARGET через `scp`.

**Аналіз на HOST** (`reports/hostinfo_cross@Roman.txt`):
- ELF64 PIE, AArch64; interpreter `/lib/ld-linux-aarch64.so.1`
- NEEDED: `libc.so.6` і `ld-linux-aarch64.so.1`
- розмір 70 992 байти; `size`: text 3270, data 744, bss 8
- потрібні версії glibc: `GLIBC_2.17` … `GLIBC_2.34`
- запуск на HOST: `Exec format error` (очікувано, чужа архітектура)
- `ldd` на HOST: `not a dynamic executable`, залежності видно лише через `readelf -d`

**Запуск і аналіз на TARGET** (`reports/hostinfo_cross@pi5.txt`):
- бінарник запустився без змін; перший запуск виводить блок у консоль,
  запуск з `out.txt` створює файл, повторний виводить
  `WARNING: file 'out.txt' exists, appending` і дописує другий блок — так
- `ldd` на TARGET працює: `libc.so.6 => /lib/aarch64-linux-gnu/libc.so.6`
- `readelf`, `size`, `strings`, розмір і BuildID збігаються з результатами на HOST
  (BuildID `6b89f56f56e6460c79c863b78e000488d87fa32f`): файл не змінився під час перенесення
- максимальна потрібна версія glibc 2.34 ≤ 2.41 на TARGET, тому сумісність є

## 5. Порівняльна таблиця
| Збірка | Де зібрано | Де запущено | Розмір, байт | Макс. GLIBC | NEEDED | Результат |
|---|---|---|---|---|---|---|
| native dynamic | HOST (x86_64) | HOST | 16 456 | 2.34 | libc.so.6 | працює |
| cross dynamic | HOST (x86_64→aarch64) | HOST | 70 992 | 2.34 | libc.so.6, ld-linux-aarch64.so.1 | `Exec format error` |
| cross dynamic | HOST (x86_64→aarch64) | TARGET | 70 992 | 2.34 | libc.so.6, ld-linux-aarch64.so.1 | працює |
| native dynamic | TARGET | TARGET | | | | |
| native static | TARGET | TARGET | | | | |
| cross static | HOST | TARGET | | | | |

## 6. Спостереження
- Код в aarch64 і x86 майже однаковий (`text` 3270 і 3080 байт), проте файл
  aarch64 більший більш ніж у чотири рази (70 992 проти 16 456 байт). Причина в
  вирівнюванні сегментів `LOAD`: в aarch64-збірці `Align 0x10000` (64 КБ), в x86
  `0x1000` (4 КБ), тому файл доповнюється до меж 64 КБ-сторінок.
- Програма використовує лише базові виклики (`uname`, `time`, `strftime`,
  `fopen`), тому мінімум `GLIBC_2.34` (це `__libc_start_main`). Збірка з HOST
  (glibc 2.43) запускається на TARGET (glibc 2.41). Якби програма викликала
  функції, додані в glibc 2.42–2.43, динамічна крос-збірка не запустилась би
  (`GLIBC_2.xx not found`), і довелось би збирати зі старішим toolchain, через
  sysroot з образу TARGET або статично.
- `ldd` показує залежності лише для бінарників власної архітектури. На HOST для
  aarch64-файлу він каже `not a dynamic executable`, тому для крос-бінарників
  користуюсь `aarch64-linux-gnu-readelf -d`.
- Розбіжності середовищ у виводі програми: часовий пояс (UTC на HOST, EEST на
  TARGET), hostname, `machine` (`x86_64` і `aarch64`).
- Права виконання не переносяться між системами автоматично: після `scp` на
  TARGET потрібен `chmod +x`.
- Для цієї програми крос-компіляція не є необхідністю: Raspberry Pi 5 з 16 ГБ
  ОЗП і стоковим gcc збирає її за долі секунди. Крос-збірка виправдана для
  великих проєктів, CI і плат без власного toolchain.
- (доповнювати в міру проходження кроків 4–5)

## 7. Висновки
(заповнити наприкінці, п. 6 завдання)
