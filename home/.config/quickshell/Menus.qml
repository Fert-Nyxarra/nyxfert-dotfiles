pragma Singleton

// ~/.config/quickshell/Menus.qml
// Контекстные меню панели открываются по одному: открывая новое, гасим
// прежнее. Иначе на панели можно было развесить сразу несколько меню —
// каждое со своим захватом ввода.
//
// ВАЖНО: pragma Singleton первой строкой, см. README, раздел «Грабли».

import QtQuick
import Quickshell

Singleton {
    property var current: null

    function opened(menu): void {
        if (current && current !== menu) current.close();
        current = menu;
    }

    function closed(menu): void {
        if (current === menu) current = null;
    }

    // Клик по самой панели открытое меню не гасит: для компоновщика панель —
    // родительская поверхность всплывающего окна, и захват ввода на ней не
    // сбрасывается. Поэтому модули панели сообщают о своих кликах сюда.
    //
    // Клик по модулю, которому меню и принадлежит, пропускаем: он сам его
    // переключит, иначе меню закрылось бы и тут же открылось снова.
    function clicked(item): void {
        if (current && current.anchorItem !== item) current.close();
    }

    function closeCurrent(): void {
        if (current) current.close();
    }
}
