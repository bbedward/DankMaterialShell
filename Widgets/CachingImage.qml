pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common

Image {
    id: root

    property string imagePath: ""
    property string imageHash: ""
    property int maxCacheSize: 512
    readonly property string cachePath: imageHash ? `${Paths.stringify(Paths.imagecache)}/${imageHash}@${maxCacheSize}x${maxCacheSize}.png` : ""

    asynchronous: true
    fillMode: Image.PreserveAspectCrop
    sourceSize.width: maxCacheSize
    sourceSize.height: maxCacheSize
    smooth: true
    onImagePathChanged: {
        if (imagePath) {
            hashProcess.command = ["sha256sum", Paths.strip(imagePath)];
            hashProcess.running = true;
        } else {
            source = "";
            imageHash = "";
        }
    }
    onCachePathChanged: {
        if (imageHash && cachePath) {
            Paths.mkdir(Paths.imagecache);
            source = cachePath;
        }
    }
    onStatusChanged: {
        if (source == cachePath && status === Image.Error) {
            source = imagePath;
        } else if (source == imagePath && status === Image.Ready && imageHash && cachePath) {
            Paths.mkdir(Paths.imagecache);
            const grabPath = cachePath;
            if (visible && width > 0 && height > 0 && Window.window && Window.window.visible)
                grabToImage((res) => {
                return res.saveToFile(grabPath);
            });

        }
    }

    Process {
        id: hashProcess

        stdout: StdioCollector {
            onStreamFinished: {
                root.imageHash = text.split(" ")[0];
            }
        }

    }

}
