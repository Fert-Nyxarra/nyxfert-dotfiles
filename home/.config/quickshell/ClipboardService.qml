pragma Singleton

// ~/.config/quickshell/ClipboardService.qml
// История буфера обмена: вызывается на SUPER + V, как в Windows.
//
// Cliphist в системе нет, и ставить его ради этого незачем: wl-clipboard уже
// стоит, а `wl-paste --watch` сам сообщает о каждой новой копии. Последние
// записи храним в ~/.local/state/quickshell/clipboard.json — переживает и
// перезагрузку конфига (её вызывает каждый запуск matugen), и перезаход.
//
// Текст лежит прямо в JSON, картинки — файлами в ~/.cache/quickshell/clipboard,
// а в истории только ссылка на файл. Имя файла — хеш содержимого, поэтому
// одна и та же картинка не плодит копий.
//
// ВАЖНО: pragma Singleton первой строкой, см. README, раздел «Грабли».

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string statePath: root.home + "/.local/state/quickshell/clipboard.json"
    readonly property string cacheDir: root.home + "/.cache/quickshell/clipboard"

    readonly property int limit: 50
    readonly property int maxLength: 20000

    readonly property var items: store.adapter && store.adapter.items
        ? store.adapter.items
        : []

    readonly property int count: root.items.length

    signal toggleRequested

    function toggle(): void {
        root.toggleRequested();
    }

    // Записи — объекты вида {kind, mime, value}. Старая история хранила
    // просто строки, поэтому строку считаем текстом.
    function kindOf(item): string {
        if (typeof item === "string") return "text";
        return item && item.kind === "image" ? "image" : "text";
    }

    // Имя именно payloadOf: valueOf в JavaScript занят Object.prototype, и
    // метод с таким именем молча подменяется встроенным — вместо значения
    // возвращается сам объект, а в буфер уезжает "[object V4ReferenceObject]".
    function payloadOf(item): string {
        if (typeof item === "string") return item;
        return item && item.value !== undefined ? item.value : "";
    }

    function mimeOf(item): string {
        return typeof item === "string" ? "" : (item && item.mime ? item.mime : "");
    }

    function preview(text: string): string {
        const line = text.trim().split("\n").find(part => part.trim() !== "") ?? "";
        return line.length > 70 ? line.slice(0, 70) + "…" : line;
    }

    // сколько строк за записью — видно, что скопирован кусок, а не слово
    function lineCount(text: string): int {
        return text.trim().split("\n").length;
    }

    // Наблюдатель присылает "вид<TAB>mime<TAB>значение". Текст может
    // содержать табы, поэтому режем ровно по двум первым.
    function remember(chunk: string): void {
        if (!store.adapter) return;
        if (chunk === undefined || chunk === null) return;

        const firstTab = chunk.indexOf("\t");
        if (firstTab < 0) return;

        const secondTab = chunk.indexOf("\t", firstTab + 1);
        if (secondTab < 0) return;

        const kind = chunk.slice(0, firstTab);
        const mime = chunk.slice(firstTab + 1, secondTab);
        let value = chunk.slice(secondTab + 1);

        if (value.trim() === "") return;
        if (kind === "text" && value.length > root.maxLength) {
            value = value.slice(0, root.maxLength);
        }

        const entry = { kind: kind, mime: mime, value: value };

        // повтор не плодим, а поднимаем наверх
        const rest = root.items.filter(item =>
            !(root.kindOf(item) === kind && root.payloadOf(item) === value));
        rest.unshift(entry);

        store.adapter.items = rest.slice(0, root.limit);
        store.writeAdapter();
    }

    function copy(item): void {
        const value = root.payloadOf(item);
        if (value === "") return;

        // wl-copy остаётся жить владельцем буфера, поэтому его отцепляем:
        // иначе quickshell прибьёт процесс вместе с завершением команды, и
        // буфер останется пустым (та же история, что со swaybg)
        if (root.kindOf(item) === "image") {
            const mime = root.mimeOf(item) === "" ? "image/png" : root.mimeOf(item);
            copyProcess.command = ["sh", "-c",
                "setsid --fork wl-copy --type \"$1\" < \"$2\"", "sh", mime, value];
        } else {
            // текст идёт через stdin: длинный упёрся бы в длину командной строки
            copyProcess.command = ["sh", "-c",
                "printf %s \"$1\" | setsid --fork wl-copy", "sh", value];
        }

        copyProcess.running = true;
    }

    function forget(item): void {
        if (!store.adapter) return;

        const kind = root.kindOf(item);
        const value = root.payloadOf(item);

        // файл картинки больше никому не нужен: имя — хеш содержимого,
        // так что на него не ссылается никакая другая запись
        if (kind === "image" && value !== "") {
            cleanupProcess.command = ["rm", "-f", value];
            cleanupProcess.running = true;
        }

        store.adapter.items = root.items.filter(other =>
            !(root.kindOf(other) === kind && root.payloadOf(other) === value));
        store.writeAdapter();
    }

    function clear(): void {
        if (!store.adapter) return;

        store.adapter.items = [];
        store.writeAdapter();

        // вместе с историей уходят и сохранённые картинки
        cleanupProcess.command = ["sh", "-c",
            "rm -f \"$1\"/*", "sh", root.cacheDir];
        cleanupProcess.running = true;
    }

    Process { id: copyProcess }
    Process { id: cleanupProcess }

    // каталог состояния может ещё не существовать
    Process {
        running: true
        command: ["mkdir", "-p", root.home + "/.local/state/quickshell"]
    }

    // Наблюдатели. По одному на тип: wl-paste --watch запускает команду
    // только когда в буфере есть запрошенный тип, и отдаёт ей содержимое в
    // stdin.
    //
    // Читать буфер изнутри обработчика (wl-paste внутри wl-paste --watch)
    // нельзя: вложенный вызов виснет намертво, копятся зомби, и ни одна
    // запись не доезжает. Поэтому только stdin.
    //
    // Ответ — "вид<TAB>mime<TAB>значение" и разделитель 0x01 в конце: записи
    // иначе слиплись бы в один поток, а этот байт в тексте не встречается.
    readonly property string imageScript:
        'd="$1"; mime="$2"; ext="$3"; mkdir -p "$d"; '
        + 'tmp="$d/.incoming.$$"; cat > "$tmp"; '
        + '[ -s "$tmp" ] || { rm -f "$tmp"; exit 0; }; '
        + "sum=$(sha256sum < \"$tmp\" | cut -c1-16); "
        + 'file="$d/$sum.$ext"; '
        + 'if [ -s "$file" ]; then rm -f "$tmp"; else mv "$tmp" "$file"; fi; '
        + 'ls -t "$d" 2>/dev/null | tail -n +51 | while read -r old; do rm -f "$d/$old"; done; '
        + "printf 'image\\t%s\\t%s\\001' \"$mime\" \"$file\""

    // текст
    Process {
        running: true
        command: ["wl-paste", "--type", "text", "--watch", "sh", "-c",
            "printf 'text\\t\\t'; cat; printf '\\001'"]

        stdout: SplitParser {
            splitMarker: "\u0001"
            onRead: data => root.remember(data)
        }
    }

    // картинки: PNG и JPEG — в этих типах их отдают браузеры и мессенджеры.
    // Repeater тут не годится: он умеет порождать только Item'ы, а Process
    // им не является.
    Process {
        running: true
        command: ["wl-paste", "--type", "image/png", "--watch", "sh", "-c",
            root.imageScript, "sh", root.cacheDir, "image/png", "png"]

        stdout: SplitParser {
            splitMarker: "\u0001"
            onRead: data => root.remember(data)
        }
    }

    Process {
        running: true
        command: ["wl-paste", "--type", "image/jpeg", "--watch", "sh", "-c",
            root.imageScript, "sh", root.cacheDir, "image/jpeg", "jpg"]

        stdout: SplitParser {
            splitMarker: "\u0001"
            onRead: data => root.remember(data)
        }
    }

    FileView {
        id: store

        path: root.statePath
        watchChanges: true
        onFileChanged: store.reload()

        // файла может не быть — тогда просто пустая история
        onLoadFailed: store.writeAdapter()

        adapter: JsonAdapter {
            property var items: []
        }
    }
}
