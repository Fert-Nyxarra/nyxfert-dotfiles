// ~/.config/quickshell/bar/NowPlaying.qml
// Что сейчас играет: эквалайзер и название трека справа от рабочих столов.
//
// Браузеры намеренно отфильтрованы: у любой вкладки с видео есть MPRIS, и
// панель дёргалась бы на каждый ролик. Остаются «настоящие» плееры —
// Spotify, Telegram/AyuGram, музыкальные клиенты.
//
// ЛКМ — меню с перемоткой, ПКМ — пауза, колесо — перемотка на ±5 с.

import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import qs
import qs.widgets

BarItem {
    id: root

    // по этим словам в имени источника понимаем, что это браузер
    readonly property var browsers: [
        "chrome", "chromium", "firefox", "brave", "vivaldi", "opera", "edge",
        "yandex", "librewolf", "waterfox", "floorp", "zen", "qutebrowser",
        "epiphany", "midori", "falkon", "safari", "webcord"
    ]

    function isBrowser(player): bool {
        const name = ((player.desktopEntry ?? "") + " "
            + (player.identity ?? "") + " "
            + (player.dbusName ?? "")).toLowerCase();

        return root.browsers.some(browser => name.includes(browser));
    }

    readonly property var player: {
        const players = Mpris.players ? Mpris.players.values : [];
        const usable = players.filter(p => !root.isBrowser(p));

        if (usable.length === 0) return null;
        return usable.find(p => p.isPlaying) ?? usable[0];
    }

    readonly property bool playing: root.player !== null && root.player.isPlaying

    // показываемся, когда что-то играет или хотя бы известен трек
    visible: root.player !== null
        && (root.playing || root.player.trackTitle !== "" || root.player.trackArtist !== "")

    horizontalPadding: 10
    spacing: 8
    interactive: true
    active: menu.opened

    onClicked: menu.toggle()

    onRightClicked: {
        if (root.player && root.player.canTogglePlaying) root.player.togglePlaying();
    }

    onWheel: delta => {
        if (!root.player || !root.player.canSeek) return;

        const step = delta > 0 ? 5 : -5;
        root.player.position = Math.max(0, root.player.position + step);
    }

    MediaMenu {
        id: menu
        anchorItem: root
        player: root.player
    }

    Equalizer {
        anchors.verticalCenter: parent.verticalCenter
        playing: root.playing
        barColor: root.playing ? Colors.primary : Colors.outline
    }

    BarText {
        color: root.playing ? Colors.text : Colors.subtext
        width: Math.min(implicitWidth, 260)

        text: {
            if (!root.player) return "";

            const title = root.player.trackTitle;
            const artist = root.player.trackArtist;

            // без тегов (бывает у локальных файлов) показываем сам источник
            if (title === "" && artist === "") return root.player.identity;
            if (title === "") return artist;
            if (artist === "") return title;
            return artist + " — " + title;
        }
    }
}
