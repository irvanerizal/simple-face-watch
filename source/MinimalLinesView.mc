import Toybox.ActivityMonitor;
import Toybox.Application;
import Toybox.Application.Properties;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

//! Minimal Lines - stacked inline-digit time with a pink palette.
//! Hours and minutes are stacked in the centre using a huge Monoton
//! bitmap font (striped/inline style); data slots sit top and bottom,
//! the date runs down both sides as single stacked characters.
class MinimalLinesView extends WatchUi.WatchFace {

    //! Monoton 148px digit font (see resources/fonts/fonts.xml)
    private var _fTime as Graphics.FontType?;
    //! Bold sans for data slots and side columns
    private var _fData as Graphics.FontType?;

    // "Rose + Burgundy" colorway
    private const HOUR_COLOR = 0xFF8FA3;     // rose: hours + top slot
    private const MINUTE_COLOR = 0xC2123F;   // burgundy: minutes
    private const ACCENT_COLOR = 0xFF8FA3;   // rose: bottom slot + side columns

    // Data slot types (mirrors settings.xml)
    private const SLOT_STEPS = 0;
    private const SLOT_HR = 1;
    private const SLOT_CALORIES = 2;
    private const SLOT_BATTERY = 3;

    function initialize() {
        WatchFace.initialize();
        _fTime = null;
        _fData = null;
    }

    function onLayout(dc as Dc) as Void {
    }

    function onUpdate(dc as Dc) as Void {
        if (dc has :setAntiAlias) {
            dc.setAntiAlias(true);
        }
        ensureFonts();

        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = w / 2;

        var hoursColor = propColor("hoursColor", HOUR_COLOR);
        var minuteColor = MINUTE_COLOR;
        var accentColor = propColor("accentColor", ACCENT_COLOR);

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // ---- Stacked time (core element) ----
        var clock = System.getClockTime();
        var hour = clock.hour;
        if (!System.getDeviceSettings().is24Hour) {
            if (hour == 0) {
                hour = 12;
            } else if (hour > 12) {
                hour -= 12;
            }
        }

        // ~120px glyphs, 14px gap between the hour and minute lines,
        // 8px letter spacing between digits
        var fTime = _fTime as Graphics.FontType;
        var digitGap = (w * 0.019).toNumber();     // ~8px @ 416
        dc.setColor(hoursColor, Graphics.COLOR_TRANSPARENT);
        drawDigits(dc, cx, (h * 0.338).toNumber(), hour.format("%02d"), fTime, digitGap);
        dc.setColor(minuteColor, Graphics.COLOR_TRANSPARENT);
        drawDigits(dc, cx, (h * 0.662).toNumber(), clock.min.format("%02d"), fTime, digitGap);

        // ---- Top data slot (heart rate by default) ----
        drawSlot(dc, cx, (h * 0.12).toNumber(), propInt("topSlot", SLOT_HR), hoursColor);

        // ---- Bottom data slot (steps by default) ----
        drawSlot(dc, cx, (h * 0.88).toNumber(), propInt("bottomSlot", SLOT_STEPS), accentColor);

        // ---- Side vertical date columns, close to the screen edges ----
        var date = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        var fData = _fData as Graphics.FontType;
        var lineSpacing = (dc.getFontHeight(fData) * 1.35).toNumber();
        drawVerticalText(dc, (w * 0.09).toNumber(), h / 2, monthText(date),
            fData, lineSpacing, accentColor);
        drawVerticalText(dc, (w * 0.91).toNumber(), h / 2, date.day.format("%02d"),
            fData, lineSpacing, accentColor);
    }

    // ------------------------------------------------------------------
    // Text helpers
    // ------------------------------------------------------------------

    //! Big digits with horizontal letter spacing, centred on x
    private function drawDigits(dc as Dc, x as Number, y as Number, text as String,
        font as Graphics.FontType, spacing as Number) as Void {
        var total = -spacing;
        for (var i = 0; i < text.length(); i++) {
            total += dc.getTextWidthInPixels(text.substring(i, i + 1), font) + spacing;
        }
        var px = x - total / 2;
        for (var i = 0; i < text.length(); i++) {
            var c = text.substring(i, i + 1);
            dc.drawText(px, y, font, c,
                Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
            px += dc.getTextWidthInPixels(c, font) + spacing;
        }
    }

    //! Render a string character by character, stacked vertically and
    //! centred on (x, centerY) with the given line spacing.
    private function drawVerticalText(dc as Dc, x as Number, centerY as Number,
        text as String, font as Graphics.FontType, lineSpacing as Number,
        color as Number) as Void {
        var count = text.length();
        var y = centerY - ((count - 1) * lineSpacing) / 2;
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        for (var i = 0; i < count; i++) {
            dc.drawText(x, y, font, text.substring(i, i + 1),
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            y += lineSpacing;
        }
    }

    //! Data slot: value text with its icon on the right, centred on cx
    private function drawSlot(dc as Dc, cx as Number, y as Number, slot as Number,
        color as Number) as Void {
        var fData = _fData as Graphics.FontType;
        var value = slotValue(slot);
        var iconSize = (dc.getWidth() * 0.048).toNumber();   // ~20px @ 416
        var tw = dc.getTextWidthInPixels(value, fData);
        var gap = (iconSize * 0.55).toNumber() + 3;
        var x = cx - (tw + gap + iconSize) / 2;

        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, fData, value,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        drawIcon(dc, (x + tw + gap + iconSize / 2).toNumber(), y, slot, color, iconSize);
    }

    // ------------------------------------------------------------------
    // Icons (pure vector, no external bitmaps)
    // ------------------------------------------------------------------

    private function drawIcon(dc as Dc, x as Number, y as Number, slot as Number,
        color as Number, size as Number) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        if (slot == SLOT_STEPS) {
            drawFootsteps(dc, x, y, size);
        } else if (slot == SLOT_HR) {
            drawHeart(dc, x, y, size);
        } else if (slot == SLOT_CALORIES) {
            drawFlame(dc, x, y, size);
        } else {
            drawBatteryIcon(dc, x, y, size, batteryPercent());
        }
    }

    //! Two footprint soles (outline) with toe dots, left-right like 👣
    private function drawFootsteps(dc as Dc, cx as Number, cy as Number, size as Number) as Void {
        var s = size / 2.0;
        dc.setPenWidth(2);
        // back sole (left, slightly lower)
        dc.drawEllipse(cx - s * 0.52, cy + s * 0.22, s * 0.32, s * 0.52);
        dc.fillCircle(cx - s * 0.72, cy - s * 0.42, 2);
        dc.fillCircle(cx - s * 0.34, cy - s * 0.52, 2);
        // front sole (right, slightly higher)
        dc.drawEllipse(cx + s * 0.52, cy - s * 0.22, s * 0.32, s * 0.52);
        dc.fillCircle(cx + s * 0.32, cy - s * 0.88, 2);
        dc.fillCircle(cx + s * 0.70, cy - s * 0.98, 2);
    }

    //! Hollow heart: two arc lobes meeting at a dip, two sides to the tip
    private function drawHeart(dc as Dc, cx as Number, cy as Number, size as Number) as Void {
        var r = (size * 0.26).toNumber();
        var topY = (cy - size * 0.14).toNumber();
        var tipY = (cy + size * 0.46).toNumber();
        dc.setPenWidth(2);
        dc.drawArc(cx - r, topY, r, Graphics.ARC_COUNTER_CLOCKWISE, 0, 180);
        dc.drawArc(cx + r, topY, r, Graphics.ARC_COUNTER_CLOCKWISE, 0, 180);
        dc.drawLine(cx - 2 * r, topY, cx, tipY);
        dc.drawLine(cx + 2 * r, topY, cx, tipY);
    }

    //! Simple teardrop flame for the calories slot
    private function drawFlame(dc as Dc, cx as Number, cy as Number, size as Number) as Void {
        var s = size / 2.0;
        var pts = [
            [cx, (cy - s * 1.05).toNumber()],
            [(cx + s * 0.70).toNumber(), (cy - s * 0.10).toNumber()],
            [(cx + s * 0.52).toNumber(), (cy + s * 0.72).toNumber()],
            [cx, (cy + s).toNumber()],
            [(cx - s * 0.52).toNumber(), (cy + s * 0.72).toNumber()],
            [(cx - s * 0.70).toNumber(), (cy - s * 0.10).toNumber()]
        ] as Array<Graphics.Point2D>;
        dc.fillPolygon(pts);
    }

    //! Battery outline with a fill bar for the battery slot
    private function drawBatteryIcon(dc as Dc, cx as Number, cy as Number,
        size as Number, pct as Number) as Void {
        var bw = (size * 0.80).toNumber();
        var bh = (size * 0.48).toNumber();
        dc.setPenWidth(1);
        dc.drawRoundedRectangle(cx - bw / 2, cy - bh / 2, bw, bh, 2);
        dc.fillRectangle(cx + bw / 2, cy - bh / 4, 2, bh / 2);
        dc.fillRectangle(cx - bw / 2 + 2, cy - bh / 2 + 2, (bw - 4) * pct / 100, bh - 4);
    }

    // ------------------------------------------------------------------
    // Fonts & settings
    // ------------------------------------------------------------------

    //! Monoton digits + a bold sans for data/side text
    private function ensureFonts() as Void {
        if (_fTime == null) {
            _fTime = WatchUi.loadResource(Rez.Fonts.TimeDigits) as Graphics.FontType;
        }
        if (_fData == null) {
            if (Graphics has :getVectorFont) {
                _fData = Graphics.getVectorFont({
                    :face => ["RobotoCondensedBold", "RobotoBlack", "NanumGothicBold",
                              "BionicBold", "Swiss721Bold"] as Array<String>,
                    :size => 29
                });
            }
            if (_fData == null) {
                _fData = Graphics.FONT_TINY;
            }
        }
    }

    private function propColor(key as String, fallback as Number) as Number {
        var value = Properties.getValue(key);
        return value != null ? (value as Number) : fallback;
    }

    private function propInt(key as String, fallback as Number) as Number {
        var value = Properties.getValue(key);
        return value != null ? (value as Number) : fallback;
    }

    // ------------------------------------------------------------------
    // Data helpers
    // ------------------------------------------------------------------

    private function slotValue(slot as Number) as String {
        if (slot == SLOT_STEPS) {
            return formatSteps(steps());
        }
        if (slot == SLOT_HR) {
            return heartRate();
        }
        if (slot == SLOT_CALORIES) {
            return numberOrDash(ActivityMonitor.getInfo().calories);
        }
        return batteryPercent().toString() + "%";
    }

    //! 12345 -> "12.3k", 950 -> "950"
    private function formatSteps(steps as Number) as String {
        if (steps >= 1000) {
            var tenths = steps / 100;
            return (tenths / 10).toString() + "." + (tenths % 10).toString() + "k";
        }
        return steps.toString();
    }

    private function steps() as Number {
        var steps = ActivityMonitor.getInfo().steps;
        return steps != null ? steps : 0;
    }

    private function heartRate() as String {
        var sample = ActivityMonitor.getHeartRateHistory(1, true).next();
        if (sample != null && sample.heartRate != null) {
            return sample.heartRate.toString();
        }
        return "--";
    }

    private function batteryPercent() as Number {
        var pct = System.getSystemStats().battery.toNumber();
        return pct > 100 ? 100 : (pct < 0 ? 0 : pct);
    }

    private function numberOrDash(value as Number or Null) as String {
        return value != null ? value.toString() : "--";
    }

    //! 3-letter month abbreviation (localised by the device language).
    //! Gregorian.Info.month is a String with FORMAT_MEDIUM, a Number otherwise.
    private function monthText(date as Gregorian.Info) as String {
        var month = date.month;
        if (month instanceof String) {
            return (month as String).toUpper();
        }
        var months = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN",
                      "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"] as Array<String>;
        return months[(month as Number) - 1];
    }
}
