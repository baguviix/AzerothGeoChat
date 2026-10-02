# AzerothGeoChat (WoW 3.3.5a)

[![Interface](https://img.shields.io/badge/WoW_Interface-30300_(3.3.5a)-orange.svg)](https://wowpedia.fandom.com/wiki/TOC)
[![Client](https://img.shields.io/badge/Client_Build-12340-blue.svg)](https://wowpedia.fandom.com/wiki/Build_12340)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Language](https://img.shields.io/badge/Language-Georgian_(ქართული)-green.svg)]()

**AzerothGeoChat** არის მსუბუქი, zero-dependency AddOn-ი **World of Warcraft 3.3.5a**-სთვის (Wrath of the Lich King), რომელიც უზრუნველყოფს თამაშში სრულფასოვან ქართულ (მხედრულ) ენაზე წერასა და კითხვას.

---

## 📌 რატომ არის ეს AddOn საჭირო? (Technical Background)

1. **DirectX 9 / Windows კლავიატურის შეზღუდვა:** WoW 3.3.5a კლიენტი ვერ იღებს არასტანდარტულ (non-ANSI) Windows-ის ენობრივ განლაგებებს. როდესაც Windows-ში ჩართულია ქართული კლავიატურა, თამაშის ჩატის ველში სიმბოლოები საერთოდ არ იწერება.
2. **შრიფტების (Font Glyphs) ნაკლებობა:** ოფიციალური ინგლისური (`enUS` / `enGB`) კლიენტის შრიფტებში ქართული უნიკოდის სიმბოლოები (`U+10D0`–`U+10FA`) არ არსებობს. შესაბამისად, ქართული ასოები თამაშში ჩანს როგორც კითხვის ნიშნები (`??????`).

**AzerothGeoChat** ამ პრობლემებს აგვარებს:
* კლავიატურაზე ინგლისური QWERTY ღილაკების აკრეფისას ტექსტი მყისიერად კონვერტირდება შესაბამის ქართულ მხედრულ ასოებად.
* ადონი იცავს WoW-ის ბმულებს (Hyperlinks), ჩურჩულის სახელებს (Whisper Targets) და სისტემურ ბრძანებებს (`/cast`, `/target`, `/run` და ა.შ.).
* მოყვება შრიფტების ავტომატური ინსტალატორი Windows-ის ქართული შრიფტების თამაშში დასაყენებლად.

---

## 🚀 ინსტალაციის ინსტრუქცია (Installation Guide)

### ნაბიჯი 1: AddOn-ის დაყენება
1. გადმოწერეთ ეს რეპოზიტორი (`Code` -> `Download ZIP`).
2. `AzerothGeoChat` საქაღალდე ჩასვით თქვენი თამაშის დირექტორიაში:
   ```text
   World of Warcraft/Interface/AddOns/AzerothGeoChat/
   ```
   *(დარწმუნდით, რომ ფაილები პირდაპირ ამ საქაღალდეშია: `AzerothGeoChat.toc`, `AzerothGeoChat.lua`, `Bindings.xml`)*

---

### ნაბიჯი 2: ქართული შრიფტების (Fonts) დაყენება

WoW 3.3.5a-ს გააჩნია ჩაშენებული მექანიზმი: თუ თამაშის მთავარ დირექტორიაში შექმნით საქაღალდეს სახელად `Fonts`, კლიენტი ჩაშენებული ინგლისური შრიფტების მაგივრად გამოიყენებს ამ საქაღალდეში არსებულ `.ttf` ფაილებს.

#### საჭირო 5 ფონტის სია:
| ფაილის სახელი | დანიშნულება თამაშში |
|---|---|
| **`ARIALN.ttf`** | ჩატის ძირითადი შრიფტი, რიცხვები, ჩატის ველები |
| **`FRIZQT__.ttf`** | ძირითადი ინტერფეისი, სახელები, ღილაკები, Tooltip-ები *(ყურადღება: ბოლოში 2 ქვედა ტირეა)* |
| **`MORPHEUS.ttf`** | ქვესტების ტექსტი, წიგნები, თამაშშიდა ფოსტა (Mail) |
| **`skurri.ttf`** | კომბატის ციფრები (Floating Combat Text) |
| **`FRIENDS.ttf`** | მეგობრებისა და გილდიის სია |

#### ვარიანტი A: ავტომატური დაყენება (რეკომენდებული)
გაუშვით თანდართული `Install-Fonts.ps1` PowerShell სკრიპტი:
```powershell
.\Install-Fonts.ps1 -WoWPath "C:\Games\World of Warcraft"
```
*(თუ `-WoWPath` პარამეტრს არ მიუთითებთ, სკრიპტი ავტომატურად მოძებნის WoW-ის საქაღალდეს ან თავად მოგთხოვთ გზის შეყვანას).*

#### ვარიანტი B: ხელით დაყენება (Manual)
1. შედით თქვენს `World of Warcraft` საქაღალდეში (სადაც `Wow.exe` დევს).
2. შექმენით ახალი საქაღალდე სახელად **`Fonts`**.
3. Windows-ის სისტემური საქაღალდიდან (`C:\Windows\Fonts`) დააკოპირეთ `Sylfaen.ttf` ან `Segoe UI`.
4. დააკოპირეთ ეს ფონტი `World of Warcraft/Fonts/` საქაღალდეში 5-ჯერ და დაარქვით:
   - `ARIALN.ttf`
   - `FRIZQT__.ttf`
   - `MORPHEUS.ttf`
   - `skurri.ttf`
   - `FRIENDS.ttf`

---

## ⌨️ კლავიატურის განლაგება (Keyboard Layout)

ადონი იყენებს სტანდარტულ ქართულ QWERTY განლაგებას:

| ლათინური | ქართული | ლათინური | ქართული |
|:---:|:---:|:---:|:---:|
| `a` | ა | `b` | ბ |
| `g` | გ | `d` | დ |
| `e` | ე | `v` | ვ |
| `z` | ზ | **`T`** (Shift+t) | **თ** |
| `t` | ტ | `i` | ი |
| `k` | კ | `l` | ლ |
| `m` | მ | `n` | ნ |
| `o` | ო | `p` | პ |
| **`J`** (Shift+j) | **ჟ** | `r` | რ |
| `s` | ს | `u` | უ |
| `f` | ფ | `q` | ქ |
| **`R`** (Shift+r) | **ღ** | `y` | ყ |
| **`S`** (Shift+s) | **შ** | **`C`** (Shift+c) | **ჩ** |
| `c` | ც | **`Z`** (Shift+z) | **ძ** |
| `w` | წ | **`W`** (Shift+w) | **ჭ** |
| `x` | ხ | `j` | ჯ |
| `h` | ჰ | | |

> **💡 Smart CapsLock & Shift Fallback:** თუ შემთხვევით ჩართული გაქვთ CapsLock ან სიტყვის დასაწყისში ინსტინქტურად დააჭირეთ Shift-ს (მაგ. `Gamarjoba`), ადონი `G`, `A`, `M`-ს მაინც ქართულად ჩაწერს (`გამარჯობა`) და ტექსტი არ აირევა.

---

## 🎮 ფუნქციები და მართვა (Features & Usage)

* **ჩართვა / გამორთვა (Toggle):**
  * ჩატის ველის თავზე არსებულ **`[GEO]`** / **`[ENG]`** ღილაკზე დაჭერით (მარცხენა კლიკი).
  * ჩატის ბრძანებით: `/geo` ან `/geochat` (`/geo on`, `/geo off`).
  * კლავიატურის მალმხმობით: `Escape` -> `Key Bindings` -> `AzerothGeoChat` (შეგიძლიათ მიაბათ ნებისმიერი ღილაკი, მაგ. `Ctrl+G`).
* **ადგილზევე ტექსტის გადაყვანა (Instant Convert):**
  * თუ ტექსტი უკვე აკრიფეთ ინგლისურად (მაგ. `rogor xar?`) და გინდათ ქართულად გადაყვანა, დააჭირეთ **`[GEO]` ღილაკს მარჯვენა კლიკით (Right-Click)** ან ჩატში აკრიფეთ `/geo c`!
* **ჭკვიანი Whisper & Slash ბრძანებები:**
  * `/s გამარჯობა` — ჩატის არხებზე ტექსტი გადადის ქართულად.
  * `/w Arthas გამარჯობა` — მოთამაშის ინგლისური სახელი `Arthas` უცვლელი რჩება, ხოლო შეტყობინება იწერება ქართულად.
  * `/cast Frostbolt` — საბრძოლო და სისტემური ბრძანებები არ ზიანდება.
* **თამაშშიდა ფოსტა (Mail) და მაკროები:**
  * სრულად მუშაობს ფოსტის გაგზავნის ველებში (`SendMailBodyEditBox`) და გილდიის ნოტებში.

---

## 📂 პროექტის სტრუქტურა (Project Structure)

```text
AzerothGeoChat/
├── AzerothGeoChat/             # მთავარი AddOn-ის საქაღალდე
│   ├── AzerothGeoChat.toc      # AddOn-ის მეტამონაცემები (Interface 30300)
│   ├── AzerothGeoChat.lua      # ტრანსლიტერაციის ძრავა და ლოგიკა
│   └── Bindings.xml            # Keybindings დეფინიციები
├── Install-Fonts.ps1           # ფონტების ავტომატური ინსტალატორი (PowerShell)
├── README.md                   # დოკუმენტაცია
├── LICENSE                     # MIT ლიცენზია
└── .gitignore                  # Git-ის იგნორირების ფაილი
```

---

## 📜 License

This project is licensed under the [MIT License](LICENSE).
Author: **Azeroth Reborn**
