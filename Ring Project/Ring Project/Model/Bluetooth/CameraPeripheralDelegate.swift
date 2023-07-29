//
//  CameraPeripheralDelegate.swift
//  Ring Project
//
//  Created by Yunseo Lee on 7/16/23.
//

import Foundation
import UIKit

protocol CameraPeripheralDelegate {
    /// Called when camera has all required services and characteristics discovered.
    func cameraPeripheralDidBecomeReady(_ aPeripheral: CameraPeripheral)
    /// Called when sleected device does not have required services.
    func cameraPeripheralNotSupported(_ aPeripheral: CameraPeripheral)
    /// Called when notifications were enabled.
    func cameraPeripheralDidStart(_ aPeripheral: CameraPeripheral)
    /// Called when and error occured.
    func cameraPeripheral(_ aPeripheral: CameraPeripheral, failedWithError error: Error)
    /// Full image data is complete.
    func cameraPeripheral(_ aPeripheral: CameraPeripheral, didReceiveImageData someData: UIImage?, withFps fps: Double)
    /// Value between 0 and 1 presenting completion in percentage.
    func cameraPeripheral(_ aPeripheral: CameraPeripheral, imageProgress: Float, transferRateInKbps: Double)
    /// Connection parameters did change.
    func cameraPeripheral(_ aPeripheral: CameraPeripheral, didUpdateParametersWithMTUSize mtuSize: UInt16, connectionInterval connInterval: Float, txPhy: PhyType, andRxPhy rxPhy: PhyType)
}
