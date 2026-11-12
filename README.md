# Minimal Lines — Garmin Watch Face (Monkey C)

Desain "MINIMAL LINES": time digits bergaya **inline/striped (Monoton)** ditumpuk
vertikal di tengah layar, palet pink, data slot minimalis di atas & bawah,
tanggal berjalan vertikal di kedua sisi.

> Simpan screenshot desain referensi sebagai `design.png` di root project (opsional).

## Fitur

- **Stacked time** — jam di atas (light pink `#FF85B3`), menit di bawah
  (hot pink `#FF0066`), font bitmap **Monoton 105px** (striped digits)
- **Top data slot** (Y 12%) — steps format singkat (`12.3k`) + ikon jejak kaki
- **Bottom data slot** (Y 88%) — detak jantung + ikon hati outline
- **Side columns** (X 12% & 88%) — bulan (O/C/T) dan tanggal (2/8) vertikal
- **Customizable** (Connect IQ app settings):
  - Hours Color & Accent Color (Light Pink / Hot Pink / White / Cyan)
  - Top & Bottom data slot: Steps / Heart Rate / Calories / Battery
- Semua ikon digambar **vector** (`fillEllipse`, `drawArc`, `fillPolygon`,
  `drawRoundedRectangle`) — tanpa aset bitmap eksternal
- Detik low-power: tidak ada (hemat baterai, update per menit)

## Struktur

```
minimal-lines-face/
├── manifest.xml
├── monkey.jungle
├── build.sh
├── source/
│   ├── MinimalLinesApp.mc
│   └── MinimalLinesView.mc
├── resources/
│   ├── fonts/
│   │   ├── fonts.xml
│   │   ├── Monoton105.fnt        # BMFont descriptor (glyph 0-9 + ':')
│   │   └── Monoton105.png
│   ├── drawables/
│   ├── strings/
│   └── settings/
│       ├── properties.xml        # default values
│       └── settings.xml          # opsi di Connect IQ app settings
└── tools/
```

## Build

```bash
./build.sh fr265          # hasil: bin/MinimalLines.prg
# lalu sideload ke jam: copy ke GARMIN/APPS/ (via USB mass storage / OpenMTP)
```

## Catatan font

- `Monoton105.fnt` = BMFont export dari **Monoton** (Google Fonts, OFL license),
  size 105px, tinggi glyph ±95px — optimal untuk layar **416x416 (FR265)**
- Sumber TTF gratis yang cocok untuk gaya inline/striped (di-convert via tool
  **BMFont** dari angelcode.com):
  - **Monoton** — https://fonts.google.com/specimen/Monoton (paling mirip referensi)
  - **Train One** — https://fonts.google.com/specimen/Train One
  - **Bungee Inline** — https://fonts.google.com/specimen/Bungee+Inline
  - Alternatif lain: Prisma, Rubik Puddles, Rye
- Warna digit ditentukan runtime via `dc.setColor()` — font bersifat mask,
  jadi satu font bisa dipakai untuk jam (pink) maupun menit (magenta)
- Jika ingin ganti/generate ulang font: export dari BMFont (charset Unicode,
  PNG 32-bit), lalu update `filter` di `resources/fonts/fonts.xml`

## Catatan teknis

- Font bitmap bersifat **fixed size** — saat ini dioptimalkan untuk 416px.
  Untuk device lain (360/454), generate ulang font dengan size proporsional
  (±0.25 × lebar layar) atau tambah resource qualifier per resolusi
- `drawVerticalText(dc, x, centerY, text, font, lineSpacing, color)` — helper
  render karakter per baris, bisa dipakai ulang
- Data slots memakai `ActivityMonitor` (steps/HR history) & `System.getSystemStats()`
  — tanpa permission tambahan
