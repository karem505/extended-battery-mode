#!/usr/bin/env python3
"""Extended Battery Mode — GNOME Panel Indicator

Tray icon for toggling extended battery mode with one click.
Requires: gir1.2-ayatanaappindicator3-0.1, extended-battery-mode script
"""

import gi
import json
import subprocess
import os

gi.require_version("Gtk", "3.0")
gi.require_version("AyatanaAppIndicator3", "0.1")
from gi.repository import Gtk, GLib, AyatanaAppIndicator3

SCRIPT = "/usr/local/bin/extended-battery-mode"
STATE_FILE = "/tmp/extended-battery-mode.state"
ICON_DIR = os.path.expanduser("~/.local/share/icons/hicolor/scalable/status")
ICON_ON = "extended-battery-on"
ICON_OFF = "extended-battery-off"
BACKLIGHT_PATH = "/sys/class/backlight/intel_backlight/brightness"
MAX_BRIGHTNESS = int(open("/sys/class/backlight/intel_backlight/max_brightness").read().strip()) if os.path.exists("/sys/class/backlight/intel_backlight/max_brightness") else 24000


class BatteryIndicator:
    def __init__(self):
        # Register custom icon path so GNOME can find our SVGs
        icon_theme = Gtk.IconTheme.get_default()
        icon_theme.append_search_path(ICON_DIR)

        self.indicator = AyatanaAppIndicator3.Indicator.new(
            "extended-battery-mode",
            ICON_OFF,
            AyatanaAppIndicator3.IndicatorCategory.HARDWARE,
        )
        # Use icon theme path for custom SVGs
        self.indicator.set_icon_theme_path(ICON_DIR)
        self.indicator.set_status(AyatanaAppIndicator3.IndicatorStatus.ACTIVE)
        self.build_menu()
        self.update_status()
        GLib.timeout_add_seconds(30, self.update_status)

    def build_menu(self):
        self.menu = Gtk.Menu()

        # Toggle item
        self.toggle_item = Gtk.MenuItem(label="Enable Extended Mode")
        self.toggle_item.connect("activate", self.on_toggle)
        self.menu.append(self.toggle_item)

        # Status item (non-clickable)
        self.status_item = Gtk.MenuItem(label="Status: checking...")
        self.status_item.set_sensitive(False)
        self.menu.append(self.status_item)

        # Power draw
        self.power_item = Gtk.MenuItem(label="Power: --")
        self.power_item.set_sensitive(False)
        self.menu.append(self.power_item)

        # Battery remaining
        self.remaining_item = Gtk.MenuItem(label="Remaining: --")
        self.remaining_item.set_sensitive(False)
        self.menu.append(self.remaining_item)

        self.menu.append(Gtk.SeparatorMenuItem())

        # Brightness submenu
        brightness_item = Gtk.MenuItem(label="Brightness")
        brightness_submenu = Gtk.Menu()
        for pct in [20, 40, 60, 80, 100]:
            item = Gtk.MenuItem(label=f"{pct}%")
            item.connect("activate", self.on_brightness, pct)
            brightness_submenu.append(item)
        brightness_item.set_submenu(brightness_submenu)
        self.menu.append(brightness_item)

        self.menu.append(Gtk.SeparatorMenuItem())

        # Quit
        quit_item = Gtk.MenuItem(label="Quit")
        quit_item.connect("activate", self.on_quit)
        self.menu.append(quit_item)

        self.menu.show_all()
        self.indicator.set_menu(self.menu)

    def is_on(self):
        return os.path.exists(STATE_FILE)

    def get_status(self):
        try:
            result = subprocess.run(
                ["sudo", SCRIPT, "status"],
                capture_output=True,
                text=True,
                timeout=15,
            )
            return json.loads(result.stdout)
        except Exception:
            return None

    def _do_update(self):
        """Run status check in background thread, then update UI on main thread."""
        import threading

        def _fetch():
            status = self.get_status()
            GLib.idle_add(self._apply_status, status)

        threading.Thread(target=_fetch, daemon=True).start()

    def _apply_status(self, status):
        on = self.is_on()

        if on:
            self.indicator.set_icon_full(ICON_ON, "Extended Battery Mode ON")
            self.toggle_item.set_label("Disable Extended Mode")
        else:
            self.indicator.set_icon_full(ICON_OFF, "Normal Mode")
            self.toggle_item.set_label("Enable Extended Mode")

        if status:
            bat = status.get("battery", {})
            pct = bat.get("percentage", "?")
            power = bat.get("power_draw_watts", "N/A")
            remaining = bat.get("time_remaining_hours", "N/A")
            bat_status = bat.get("status", "?")

            mode_str = "ON" if on else "OFF"
            self.status_item.set_label(f"Mode: {mode_str} | Battery: {pct}% ({bat_status})")
            self.power_item.set_label(f"Power draw: {power}W")

            if remaining != "N/A":
                hours = float(remaining)
                h = int(hours)
                m = int((hours - h) * 60)
                self.remaining_item.set_label(f"Remaining: ~{h}h {m}m")
            else:
                self.remaining_item.set_label("Remaining: N/A")

            self.indicator.set_title(f"Battery: {mode_str} | {pct}%")

        return False  # Don't repeat idle_add

    def update_status(self):
        self._do_update()
        return True  # Keep the timeout active

    def on_toggle(self, _widget):
        try:
            subprocess.Popen(
                ["sudo", SCRIPT, "toggle"],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
            # Update after a short delay to let the script finish
            GLib.timeout_add(1500, self.update_status)
        except Exception as e:
            print(f"Toggle failed: {e}")

    def on_brightness(self, _widget, pct):
        value = int(MAX_BRIGHTNESS * pct / 100)
        try:
            with open(BACKLIGHT_PATH, "w") as f:
                f.write(str(value))
        except PermissionError:
            subprocess.run(
                ["sudo", "bash", "-c", f"echo {value} > {BACKLIGHT_PATH}"],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )

    def on_quit(self, _widget):
        Gtk.main_quit()


def main():
    indicator = BatteryIndicator()
    Gtk.main()


if __name__ == "__main__":
    main()
