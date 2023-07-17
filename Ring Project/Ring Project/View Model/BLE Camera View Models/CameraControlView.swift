//
//  CameraControlView.swift
//  Ring Project
//
//  Created by Yunseo Lee on 7/16/23.
//

import SwiftUI
import CoreBluetooth

struct CameraControlView: View {
    @ObservedObject var bluetoothManager: BluetoothManager
    @ObservedObject var targetPeripheral: CameraPeripheral
    @State private var isStreaming       : Bool              = false
    @State private var currentResolution : ImageResolution   = .resolution160x120
    @State private var currentPhy        : PhyType           = .phyLE1M
    var body: some View {
        /*@START_MENU_TOKEN@*//*@PLACEHOLDER=Hello, world!@*/Text("Hello, world!")/*@END_MENU_TOKEN@*/
    }
}

extension CameraControlView: BluetoothManagerDelegate {
    func bluetoothManager(_ aManager: BluetoothManager, didUpdateState state: CBManagerState) {
        <#code#>
    }
    
    func bluetoothManager(_ aManager: BluetoothManager, didConnectPeripheral aPeripheral: CameraPeripheral) {
        <#code#>
    }
    
    func bluetoothManager(_ aManager: BluetoothManager, didDisconnectPeripheral aPeripheral: CameraPeripheral) {
        <#code#>
    }
    
    
}

extension CameraControlView: CameraPeripheralDelegate {
    func cameraPeripheralDidBecomeReady(_ aPeripheral: CameraPeripheral) {
        <#code#>
    }
    
    func cameraPeripheralNotSupported(_ aPeripheral: CameraPeripheral) {
        <#code#>
    }
    
    func cameraPeripheralDidStart(_ aPeripheral: CameraPeripheral) {
        <#code#>
    }
    
    func cameraPeripheral(_ aPeripheral: CameraPeripheral, failedWithError error: Error) {
        <#code#>
    }
    
    func cameraPeripheral(_ aPeripheral: CameraPeripheral, didReceiveImageData someData: Data, withFps fps: Double) {
        <#code#>
    }
    
    func cameraPeripheral(_ aPeripheral: CameraPeripheral, imageProgress: Float, transferRateInKbps: Double) {
        <#code#>
    }
    
    func cameraPeripheral(_ aPeripheral: CameraPeripheral, didUpdateParametersWithMTUSize mtuSize: UInt16, connectionInterval connInterval: Float, txPhy: PhyType, andRxPhy rxPhy: PhyType) {
        <#code#>
    }
    
    
}
