// Bayzite: macOS-style Plasma layout
//   top    = menu bar (logo menu, global app menu, tray, clock)
//   bottom = floating, centred dock with app icons and the trash

// ---------- Top menu bar ----------
var bar = new Panel;
bar.location = "top";
bar.height = 2 * Math.floor(gridUnit * 1.6 / 2);
bar.floating = false;
bar.hiding = "none";

var menu = bar.addWidget("org.kde.plasma.kickoff");
menu.currentConfigGroup = ["General"];
menu.writeConfig("icon", "bayzite-logo-symbolic");
menu.currentConfigGroup = ["Shortcuts"];
menu.writeConfig("global", "Alt+F1");

bar.addWidget("org.kde.plasma.appmenu");          // global menu, like macOS
bar.addWidget("org.kde.plasma.panelspacer");
bar.addWidget("org.kde.plasma.systemtray");

var clock = bar.addWidget("org.kde.plasma.digitalclock");
clock.currentConfigGroup = ["Appearance"];
clock.writeConfig("showDate", true);
clock.writeConfig("dateDisplayFormat", 1);  // 1 = beside the time
clock.writeConfig("dateFormat", "custom");
clock.writeConfig("customDateFormat", "ddd MMM d");

// ---------- Dock ----------
var dock = new Panel;
dock.location = "bottom";
dock.alignment = "center";
dock.lengthMode = "fit";
dock.floating = true;
dock.hiding = "none";
dock.height = 2 * Math.floor(gridUnit * 3.4 / 2);

var tasks = dock.addWidget("org.kde.plasma.icontasks");
tasks.currentConfigGroup = ["General"];
tasks.writeConfig("launchers", [
    "preferred://filemanager",
    "preferred://browser",
    "applications:steam.desktop",
    "applications:net.lutris.Lutris.desktop",
    "applications:io.github.kolunmi.Bazaar.desktop",
    "applications:org.kde.konsole.desktop",
    "applications:systemsettings.desktop"
]);
tasks.writeConfig("showOnlyCurrentDesktop", false);
tasks.writeConfig("groupingStrategy", 1);
tasks.writeConfig("indicateAudioStreams", true);

dock.addWidget("org.kde.plasma.marginsseparator");
dock.addWidget("org.kde.plasma.trash");

// ---------- Wallpaper (light/dark aware package) ----------
var all = desktops();
for (var i = 0; i < all.length; ++i) {
    var d = all[i];
    d.wallpaperPlugin = "org.kde.image";
    d.currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
    d.writeConfig("Image", "file:///usr/share/wallpapers/Bayzite/");
}
