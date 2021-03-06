/*
    Copyright 2017-2019 Aditya Mehra <aix.m@outlook.com>
    Copyright 2013-2017 Jan Grulich <jgrulich@redhat.com>
    
    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public
    License as published by the Free Software Foundation; either
    version 2.1 of the License, or (at your option) version 3, or any
    later version accepted by the membership of KDE e.V. (or its
    successor approved by the membership of KDE e.V.), which shall
    act as a proxy defined in Section 6 of version 3 of the license.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with this library.  If not, see <http://www.gnu.org/licenses/>.
*/

import QtQuick 2.2
import QtQuick.Layouts 1.2
import org.kde.kcoreaddons 1.0 as KCoreAddons
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.networkmanagement 0.2 as PlasmaNM
import org.kde.kirigami 2.5 as Kirigami
import Mycroft 1.0 as Mycroft

Kirigami.AbstractListItem {
    id: connectionItem

    property bool activating: model.ConnectionState == PlasmaNM.Enums.Activating
    property bool deactivating: model.ConnectionState == PlasmaNM.Enums.Deactivating
    property int  baseHeight: Math.max(units.iconSizes.medium, connectionNameLabel.height + connectionStatusLabel.height) + Math.round(units.gridUnit / 2)
    property bool predictableWirelessPassword: !model.Uuid && model.Type == PlasmaNM.Enums.Wireless &&
                                               (model.SecurityType == PlasmaNM.Enums.StaticWep || model.SecurityType == PlasmaNM.Enums.WpaPsk ||
                                                model.SecurityType == PlasmaNM.Enums.Wpa2Psk)
    
    contentItem: Item {
            implicitWidth: delegateLayout.implicitWidth;
            implicitHeight: delegateLayout.implicitHeight;
    
    ColumnLayout {
        id: delegateLayout
        anchors {
            left: parent.left;
            top: parent.top;
            right: parent.right;
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Math.round(units.gridUnit / 2)

            PlasmaCore.SvgItem {
                id: connectionSvgIcon
                Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                Layout.preferredHeight: units.iconSizes.medium
                Layout.preferredWidth: units.iconSizes.medium
                elementId: model.ConnectionIcon
                svg: PlasmaCore.Svg {
                    multipleImages: true
                    imagePath: "icons/network"
                    colorGroup: PlasmaCore.ColorScope.colorGroup
                }
            }

            ColumnLayout {
                Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft

                PlasmaComponents.Label {
                    id: connectionNameLabel
                    Layout.fillWidth: true
                    height: paintedHeight
                    elide: Text.ElideRight
                    font.weight: model.ConnectionState == PlasmaNM.Enums.Activated ? Font.DemiBold : Font.Normal
                    font.italic: model.ConnectionState == PlasmaNM.Enums.Activating ? true : false
                    text: model.ItemUniqueName
                    textFormat: Text.PlainText
                }

                PlasmaComponents.Label {
                    id: connectionStatusLabel
                    Layout.fillWidth: true
                    height: paintedHeight
                    elide: Text.ElideRight
                    font.pointSize: theme.smallestFont.pointSize
                    opacity: 0.6
                    text: itemText()
                }
            }
        }
    }
}

    function itemText() {
        if (model.ConnectionState == PlasmaNM.Enums.Activating) {
            if (model.Type == PlasmaNM.Enums.Vpn)
                return model.VpnState
            else
                return model.DeviceState
        } else if (model.ConnectionState == PlasmaNM.Enums.Deactivating) {
            if (model.Type == PlasmaNM.Enums.Vpn)
                return model.VpnState
            else
                return model.DeviceState
        } else if (model.ConnectionState == PlasmaNM.Enums.Deactivated) {
            var result = model.LastUsed
            if (model.SecurityType > PlasmaNM.Enums.NoneSecurity)
                result += ", " + model.SecurityTypeString
            return result
        } else if (model.ConnectionState == PlasmaNM.Enums.Activated) {
                return i18n("Connected")
        }
    }

    onClicked: {
        console.log(model.ConnectionPath, model.DevicePath, model.SpecificPath)
        if(!model.ConnectionPath){
            Mycroft.MycroftController.sendRequest("networkConnect.wifi", {"DevicePath": model.DevicePath, "SpecificPath": model.SpecificPath, "ConnectionName": connectionNameLabel.text, "SecurityType": model.SecurityType});
        }
        else if (model.ConnectionState == PlasmaNM.Enums.Deactivated) {
            Mycroft.MycroftController.sendText("show connecting screen");
            handler.activateConnection(model.ConnectionPath, model.DevicePath, model.SpecificPath)
        }
        else {
            handler.deactivateConnection(model.ConnectionPath, model.DevicePath)
        }
    }
    
    onPressAndHold: {
        pathToRemove = model.ConnectionPath
        networkActions.open()
    }
}
