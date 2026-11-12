# Cheat Sheet — Garmin Watch Face (Monkey C)

## 1. Setup (sekali saja per Terminal baru)

```bash
export JAVA_HOME=/opt/homebrew/opt/openjdk
```

## 2. Build

```bash
./build.sh fr265          # hasil: bin/*.prg
```

Build manual tanpa script (device lain, mis. fr965):

```bash
monkeyc -f monkey.jungle -d fr965 -o bin/app.prg -y ~/.garmin/developer_key.der -w
```

## 3. Jalankan di simulator

```bash
open ~/Applications/ConnectIQ.app     # buka simulator, biarkan terbuka
monkeydo bin/*.prg fr265              # push ke simulator (Ctrl+C untuk stop)
```

## 4. Sideload ke jam asli

```bash
cp bin/*.prg ~/Desktop/     # siapkan file untuk di-drag
```

1. Jam tercolok USB, **mode data aktif** (Settings → System → USB Mode → re-select MTP)
   - macOS tidak mount MTP di Finder → pakai **OpenMTP** (`~/Applications/OpenMTP.app`)
2. Di OpenMTP: pilih device FR265 → masuk folder **`Apps`** → drag file `.prg`
3. Eject → di jam: **Settings → Watch Face** → pilih watch face

## 5. Regenerate font BMFont (Waveform)

```bash
~/.venvs/bmfont/bin/python tools/make_bitmap_font.py
```

## 6. Git (trik retry untuk PNG)

Error `Operation not permitted` pada file PNG bersifat intermiten — retry sampai masuk:

```bash
git add -A
for f in $(git ls-files --others --exclude-standard | grep '\.png$'); do
  for i in 1 2 3 4 5; do git add "$f" 2>/dev/null && break; sleep 1; done
done
git commit -m "pesan commit"
git push
```

## 7. Iterasi cepat (3 command)

```bash
export JAVA_HOME=/opt/homebrew/opt/openjdk
./build.sh fr265
monkeydo bin/*.prg fr265
```

## Catatan

- Developer key ada di `~/.garmin/developer_key.der` — **jangan pernah di-commit**
- PRG harus di-build untuk device target-nya (build fr970 tidak jalan di fr265)
- Nama watch face di jam = `AppName` di `resources/strings/strings.xml`
- BMFont PNG harus **putih di atas transparan**, header `.fnt`:
  `alphaChnl=0 redChnl=4 greenChnl=4 blueChnl=4`
