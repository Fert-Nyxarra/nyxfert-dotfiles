pragma Singleton

// ~/.config/quickshell/WallpaperService.qml
// Обои: список файлов, выбранный «приоритетный» цвет для каждого и
// применение — swaybg, matugen и строка автозапуска в hyprland.lua.
//
// Приоритетный цвет закрепляется за конкретными обоями и хранится в
// ~/.local/state/quickshell/wallpapers.json. Пустая строка означает «авто»:
// тогда matugen сам выбирает цвет по картинке.
//
// ВАЖНО: pragma Singleton первой строкой, см. README, раздел «Грабли».

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string folder: root.home + "/Wallpapers"
    readonly property string statePath: root.home + "/.local/state/quickshell/wallpapers.json"
    readonly property string hyprlandConfig: root.home + "/.config/hypr/hyprland.lua"

    property var files: []
    property string current: ""

    // путь обоев -> закреплённый цвет ("" = выбирает matugen).
    // Читаем прямо из файла состояния: отдельное свойство со встречной
    // записью замыкало бы круг «изменилось здесь → изменилось там».
    readonly property var pins: store.adapter && store.adapter.colors
        ? store.adapter.colors
        : ({})

    // путь обоев -> контраст matugen, от -1 (глубже и насыщеннее) до 1
    // (светлее и бледнее). 0 — стандарт Material You.
    readonly property var contrastPins: store.adapter && store.adapter.contrast
        ? store.adapter.contrast
        : ({})

    // Поддерживает ли matugen --prefer. В 4.0 (та, что в nixpkgs) ключа нет,
    // и с ним matugen просто ругается на неизвестный аргумент — тема не
    // применится вовсе. Без него зато падает «авто» на картинках с
    // несколькими кандидатами цвета, так что передаём его только там, где он
    // есть.
    property bool matugenPrefers: true

    // путь обоев -> чёрно-белая тема вместо цветной
    readonly property var monoPins: store.adapter && store.adapter.mono
        ? store.adapter.mono
        : ({})

    signal toggleRequested

    function toggle(): void {
        toggleRequested();
    }

    function colorFor(path: string): string {
        return root.pins[path] ?? "";
    }

    function contrastFor(path: string): real {
        return root.contrastPins[path] ?? 0;
    }

    function monoFor(path: string): bool {
        return root.monoPins[path] === true;
    }

    function pin(path: string, color: string, contrast: real, mono: bool): void {
        const colorCopy = Object.assign({}, root.pins);
        colorCopy[path] = color;

        const contrastCopy = Object.assign({}, root.contrastPins);
        contrastCopy[path] = contrast;

        const monoCopy = Object.assign({}, root.monoPins);
        monoCopy[path] = mono;

        store.adapter.colors = colorCopy;
        store.adapter.contrast = contrastCopy;
        store.adapter.mono = monoCopy;
        store.writeAdapter();
    }

    // Аргументы matugen одни и те же для применения и для превью в
    // селекторе — иначе превью однажды разойдётся с результатом.
    //
    // `--prefer saturation` обязателен: без него matugen на многих картинках
    // падает с «Multiple source colors found» — он хочет, чтобы выбор сделал
    // человек в терминале, а у нас терминала нет.
    //
    // Чёрно-белая схема строится от нейтрального источника: она всё равно
    // не зависит ни от оттенка, ни от контраста — от любого цвета выходит
    // ровно один и тот же набор серых.
    function matugenArgs(path: string, color: string, contrast: real, mono: bool): var {
        if (mono) return ["-t", "scheme-monochrome", "color", "hex", "#808080"];

        let args = ["-t", "scheme-content"];
        if (contrast !== 0) args = args.concat(["--contrast", String(contrast)]);

        if (color !== "") return args.concat(["color", "hex", color]);

        return root.matugenPrefers
            ? args.concat(["image", path, "--prefer", "saturation"])
            : args.concat(["image", path]);
    }

    // применяем: обои, палитра, автозапуск
    function apply(path: string): void {
        if (path === "") return;

        root.current = path;
        const color = root.colorFor(path);

        // Смена обоев целиком уезжает в ОДНУ отцепленную команду, и это не
        // украшательство: matugen переписывает Colors.qml, quickshell на это
        // перезагружает конфиг, а перезагрузка убивает все недоделанные
        // процессы сервиса. Раньше шаги шли по цепочке через QML, и если
        // matugen успевал раньше (с закреплённым цветом он быстрый — не
        // разбирает картинку), обои не менялись вовсе: применялась только
        // палитра, а сами обои — лишь со второго раза, когда цвета уже
        // совпадали и перезагрузки не было.
        wallpaperSwap.command = ["setsid", "--fork", "sh", "-c", root.swapScript, "sh", path];
        wallpaperSwap.running = true;

        generateColors.command = ["matugen"].concat(
            root.matugenArgs(path, color, root.contrastFor(path), root.monoFor(path)));
        generateColors.running = true;

        root.saveAutostart(path);
    }

    // Новый swaybg поднимается ПОВЕРХ старого, и только потом старый
    // убивается: если сделать наоборот, между ними не остаётся ни одного слоя
    // обоев и на треть секунды видно собственный фон Hyprland.
    //
    // Ждём появления нового слоя и добавляем запас: hyprctl показывает
    // поверхность раньше, чем та отрисуется (замерено — на 280 мс).
    readonly property string swapScript:
        "old=$(pgrep swaybg | tr '\\n' ' '); "
        + 'before=$(hyprctl layers -j | grep -c \'"namespace": "wallpaper"\'); '
        // вывод обязательно в /dev/null: quickshell закрывает pipe, когда
        // команда завершилась, и отцепленный swaybg умирает от SIGPIPE на
        // своей же стартовой строчке лога
        + 'setsid --fork swaybg -i "$1" -m fill >/dev/null 2>&1; '
        + 'i=0; while [ "$i" -lt 50 ]; do '
        + '  now=$(hyprctl layers -j | grep -c \'"namespace": "wallpaper"\'); '
        + '  [ "$now" -gt "$before" ] && break; '
        + '  i=$((i+1)); sleep 0.1; '
        + 'done; '
        + 'sleep 0.6; '
        + '[ -n "$old" ] && kill $old 2>/dev/null; '
        + 'exit 0'

    function quote(text: string): string {
        return "'" + text.replace(/'/g, "'\\''") + "'";
    }

    // переписываем строку swaybg в автозапуске hyprland.lua
    function saveAutostart(path: string): void {
        const line = 'hl.exec_cmd("swaybg -i ' + path + '")';

        saveLine.command = ["setsid", "--fork", "sh", "-c",
            "sed -i 's|hl.exec_cmd(\"swaybg -i [^\"]*\")|" + line.replace(/[|&]/g, "\\\\&") + "|' "
            + root.quote(root.hyprlandConfig)];
        saveLine.running = true;
    }

    // спрашиваем версию один раз при запуске
    Process {
        running: true
        command: ["matugen", "--version"]

        stdout: StdioCollector {
            onStreamFinished: {
                // "matugen 4.2.0"
                const parts = this.text.trim().split(/\s+/);
                const numbers = (parts.length > 1 ? parts[1] : "0").split(".");
                const major = parseInt(numbers[0]) || 0;
                const minor = parseInt(numbers[1]) || 0;

                root.matugenPrefers = major > 4 || (major === 4 && minor >= 1);
            }
        }
    }

    Process { id: wallpaperSwap }
    Process { id: generateColors }
    Process { id: saveLine }

    // список обоев в папке
    Process {
        running: true
        command: ["sh", "-c",
            "find " + root.quote(root.folder) + " -maxdepth 1 -type f "
            + "\\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) | sort"]

        stdout: StdioCollector {
            onStreamFinished: {
                const list = this.text.trim().split("\n").filter(line => line !== "");
                root.files = list;

                if (root.current === "" && list.length > 0) root.current = list[0];
            }
        }
    }

    // Какие обои стоят сейчас — читаем из строки автозапуска. Своей памяти
    // у синглтона нет: matugen переписывает Colors.qml, панель на это
    // перезагружает конфиг, и всё состояние обнулилось бы.
    Process {
        running: true
        command: ["sh", "-c",
            "grep -o 'swaybg -i [^\"]*' " + root.quote(root.hyprlandConfig)
            + " | head -1 | sed 's|swaybg -i ||'"]

        stdout: StdioCollector {
            onStreamFinished: {
                const path = this.text.trim();
                if (path !== "") root.current = path;
            }
        }
    }

    // каталог для состояния может ещё не существовать
    Process {
        running: true
        command: ["mkdir", "-p", root.home + "/.local/state/quickshell"]
    }

    FileView {
        id: store

        path: root.statePath
        watchChanges: true
        onFileChanged: store.reload()

        // файла может не быть — это нормально, тогда просто пустая карта
        onLoadFailed: store.writeAdapter()

        adapter: JsonAdapter {
            property var colors: ({})
            property var contrast: ({})
            property var mono: ({})
        }
    }
}
