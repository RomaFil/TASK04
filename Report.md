# TASK04 — hostinfo: збірка на HOST і TARGET

## 1. Мета і склад репозиторію
Програма `hostinfo.c` виводить hostname, час, ОС і архітектуру (`uname`, `time`),
за аргументом дописує вивід у файл (з попередженням, якщо файл існує).

| Файл | Призначення |
|---|---|
| `hostinfo.c` | програма |
| `build_host.sh` | нативна динамічна збірка + тест + аналіз |
| `build_target.sh` | крос-збірка `aarch64-linux-gnu-gcc` |
| `build_static.sh` | збірка з `-static` |
| `analyze.sh` | аналіз binutils (file, readelf, ldd, size, strings) |
| `reports/` | сирі результати аналізу |

## 2. Середовище
| | HOST | TARGET |
|---|---|---|
| Машина | ПК, WSL2 Ubuntu 26.04 | Raspberry Pi 5, 16 ГБ |
| Архітектура | x86_64 | aarch64 |
| gcc | 15.2.0 (Ubuntu 15.2.0-16ubuntu1) | (заповнити) |
| glibc | (`ldd --version`) | (заповнити) |

## 3. Крок 2 — нативна збірка на HOST
Команда: `gcc -std=c11 -Wall -Wextra -Werror -O2 hostinfo.c`.

**Перевірка працездатності:**
- вивід у консоль містить hostname, час, OS, версію, архітектуру — так;
- перший запуск з файлом створює його, другий виводить
  `WARNING: file 'build/t.txt' exists, appending` і дописує другий блок — так.

**Аналіз binutils** (`reports/hostinfo_native@Roman.txt`):
- ELF64 PIE, x86-64, динамічний; interpreter `/lib64/ld-linux-x86-64.so.2`
- залежність лише `libc.so.6`
- розмір 16 456 байт; `size`: text 3080, data 664, bss 48
- потрібні версії glibc: до `GLIBC_2.34`
- у `strings` є `__fprintf_chk`, `__stack_chk_fail` — Ubuntu вмикає
  FORTIFY_SOURCE і stack protector за замовчуванням

## 4. Крок 3 — крос-збірка HOST→TARGET (результати аналізу)
(`reports/hostinfo_cross@Roman.txt`)
- ELF64 PIE, AArch64; interpreter `/lib/ld-linux-aarch64.so.1`
- NEEDED: `libc.so.6` і `ld-linux-aarch64.so.1`
- розмір 70 992 байт; `size`: text 3270, data 744, bss 8
- потрібні версії glibc: `GLIBC_2.17` … `GLIBC_2.34`
- запуск на HOST: `Exec format error` (очікувано, чужа архітектура)
- `ldd` на HOST: `not a dynamic executable`, залежності видно лише через `readelf -d`

Запуск на TARGET: (заповнити після перенесення)

## 5. Порівняльна таблиця
| Збірка | Де зібрано | Де запущено | Розмір | Макс. GLIBC | Результат |
|---|---|---|---|---|---|
| native dynamic | HOST | HOST | 16 456 | 2.34 | працює |
| cross dynamic | HOST | TARGET | 70 992 | 2.34 | (заповнити) |
| native dynamic | TARGET | TARGET | | | |
| native static | TARGET | TARGET | | | |
| cross static | HOST | TARGET | | | |

## 6. Спостереження
- Код майже однаковий (text 3080 проти 3270 байт), а файл в aarch64 більший майже
  вчетверо: сегменти вирівнюються під 64 КБ сторінки.
- Версія glibc HOST (Ubuntu 26.04) новіша за очікувану на TARGET (bookworm 2.36);
  для цієї програми мінімум `GLIBC_2.34`, тому сумісність збережена, але з новішим API вона б зламалась.
- (доповнювати в міру проходження кроків)

## 7. Висновки
(заповнити наприкінці, п. 6 завдання)
