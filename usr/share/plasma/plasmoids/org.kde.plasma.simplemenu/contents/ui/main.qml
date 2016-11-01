/***************************************************************************
 *   Copyright (C) 2014-2015 by Eike Hein <hein@kde.org>                   *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This program is distributed in the hope that it will be useful,       *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *   GNU General Public License for more details.                          *
 *                                                                         *
 *   You should have received a copy of the GNU General Public License     *
 *   along with this program; if not, write to the                         *
 *   Free Software Foundation, Inc.,                                       *
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA .        *
 ***************************************************************************/

import QtQuick 2.0
import QtQuick.Layouts 1.1
import org.kde.plasma.plasmoid 2.0

import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents

import org.kde.plasma.private.simplemenu 0.1 as SimpleMenu

Item {
    id: kicker

    anchors.fill: parent

    signal reset

    property bool isDash: (plasmoid.pluginName == "org.kde.plasma.kickerdash")

    // this is a bit of a hack to prevent Plasma from spawning a dialog on its own when we're Dash
    Plasmoid.preferredRepresentation: isDash ? Plasmoid.fullRepresentation : Plasmoid.compactRepresentation

    Plasmoid.compactRepresentation: isDash ? null : compactRepresentation
    Plasmoid.fullRepresentation: isDash ? compactRepresentation : menuRepresentation

    property QtObject itemListDialogComponent: Qt.createComponent("ItemListDialog.qml");
    property Item dragSource: null

    property QtObject globalFavorites: rootModel.favoritesModel
    property QtObject systemFavorites: rootModel.systemFavoritesModel

    onSystemFavoritesChanged: {
        systemFavorites.enabled = false;
        systemFavorites.favorites = plasmoid.configuration.favoriteSystemActions;
        systemFavorites.maxFavorites = 4;
    }

    function action_menuedit() {
        processRunner.runMenuEditor();
    }

    function updateSvgMetrics() {
        lineSvg.horLineHeight = lineSvg.elementSize("horizontal-line").height;
        lineSvg.vertLineWidth = lineSvg.elementSize("vertical-line").width;
    }

    Component {
        id: compactRepresentation
        CompactRepresentation {}
    }

    Component {
        id: menuRepresentation
        MenuRepresentation {}
    }

    SimpleMenu.RootModel {
        id: rootModel

        appNameFormat: plasmoid.configuration.appNameFormat
        flat: true
        showSeparators: false
        appletInterface: plasmoid

        showAllSubtree: true
        showRecentApps: plasmoid.configuration.showRecentApps
        showRecentDocs: plasmoid.configuration.showRecentDocs
        showRecentContacts: plasmoid.configuration.showRecentContacts

        onShowRecentAppsChanged: {
            plasmoid.configuration.showRecentApps = showRecentApps;
        }

        onShowRecentDocsChanged: {
            plasmoid.configuration.showRecentDocs = showRecentDocs;
        }

        onShowRecentContactsChanged: {
            plasmoid.configuration.showRecentContacts = showRecentContacts;
        }

        Component.onCompleted: {
            favoritesModel.favorites = plasmoid.configuration.favoriteApps;
            favoritesModel.maxFavorites = 12;
        }
    }

    Connections {
        target: globalFavorites

        onFavoritesChanged: {
            plasmoid.configuration.favoriteApps = target.favorites;
        }
    }

    Connections {
        target: systemFavorites

        onFavoritesChanged: {
            plasmoid.configuration.favoriteSystemActions = target.favorites;
        }
    }

    Connections {
        target: plasmoid.configuration

        onFavoriteAppsChanged: {
            globalFavorites.favorites = plasmoid.configuration.favoriteApps;
        }

        onFavoriteSystemActionsChanged: {
            systemFavorites.favorites = plasmoid.configuration.favoriteSystemActions;
        }
    }

    SimpleMenu.RunnerModel {
        id: runnerModel

        favoritesModel: globalFavorites
        runners: plasmoid.configuration.useExtraRunners ? new Array("services").concat(plasmoid.configuration.extraRunners) : "services"

        deleteWhenEmpty: false
    }

    SimpleMenu.DragHelper {
        id: dragHelper
    }

    SimpleMenu.ProcessRunner {
        id: processRunner;
    }

    SimpleMenu.WindowSystem {
        id: windowSystem;
    }

    PlasmaCore.FrameSvgItem {
        id : highlightItemSvg

        visible: false

        imagePath: "widgets/viewitem"
        prefix: "hover"
    }

    PlasmaCore.FrameSvgItem {
        id : listItemSvg

        visible: false

        imagePath: "widgets/listitem"
        prefix: "normal"
    }

    PlasmaCore.Svg {
        id: arrows

        imagePath: "widgets/arrows"
        size: "16x16"
    }

    PlasmaCore.Svg {
        id: lineSvg
        imagePath: "widgets/line"

        property int horLineHeight
        property int vertLineWidth
    }

    PlasmaComponents.Label {
        id: toolTipDelegate

        width: contentWidth
        height: contentHeight

        property Item toolTip

        text: (toolTip != null) ? toolTip.text : ""
    }

    Timer {
        id: justOpenedTimer

        repeat: false
        interval: 600
    }

    Connections {
        target: plasmoid

        onExpandedChanged: {
            if (expanded) {
                windowSystem.monitorWindowVisibility(plasmoid.fullRepresentationItem);
                justOpenedTimer.start();
            } else {
                kicker.reset();
            }
        }
    }

    function resetDragSource() {
        dragSource = null;
    }

    function enableHideOnWindowDeactivate() {
        plasmoid.hideOnWindowDeactivate = true;
    }

    Component.onCompleted: {
        windowSystem.focusOut.connect(enableHideOnWindowDeactivate);
        plasmoid.hideOnWindowDeactivate = true;

        plasmoid.setAction("menuedit", i18n("Edit Applications..."));

        updateSvgMetrics();
        theme.themeChanged.connect(updateSvgMetrics);

        rootModel.refreshed.connect(reset);

        dragHelper.dropped.connect(resetDragSource);
    }
}