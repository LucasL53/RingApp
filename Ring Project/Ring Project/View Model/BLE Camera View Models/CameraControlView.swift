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
    @State private var targetPeripheral: CameraPeripheral?
    @State private var isStreaming       : Bool              = false
    @State private var currentResolution : ImageResolution   = .resolution160x120
    @State private var currentPhy        : PhyType           = .phyLE1M
    @State private var isDeviceConnected = false;
    @State private var showAlert = false;
    @State private var imageData : UIImage?
    var body: some View {
        ZStack (alignment: .topLeading) {
            Image(uiImage: imageData ?? UIImage(ciImage: .black))
                .frame(width: 100, height: 50)
                .padding()
                .background(.gray)
            Button(action: {
                setup()
            }){
                Text("Bluetooth")
            }
            .padding(10)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .alignmentGuide(.top) { d in
                d[.bottom]
            }
            .alignmentGuide(.leading) { d in
                d[.trailing]
            }
        }
    }
    
    func setup() {
        if (!isDeviceConnected) {
            bluetoothManager.scanForPeripherals(withDiscoveryHandler: { (aPeripheral, RSSI) in
                if (aPeripheral.name == "Test" && targetPeripheral == nil) {
                    self.targetPeripheral = CameraPeripheral(withPeripheral: aPeripheral)
                    if (self.targetPeripheral == nil) {
                        print("Error finding peripheral")
                    }
                    bluetoothManager.connect(peripheral: self.targetPeripheral!)
                }
            })
        }
        else {
            targetPeripheral?.stopStream()
            bluetoothManager.disconnect()
        }
    }
}

extension CameraControlView: BluetoothManagerDelegate, CameraPeripheralDelegate {
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
    
    func bluetoothManager(_ aManager: BluetoothManager, didUpdateState state: CBManagerState) {
        if state != .poweredOn {
            print("Bluetooth Not On")
            if (targetPeripheral != nil) {
                bluetoothManager(aManager, didDisconnectPeripheral: targetPeripheral!)
            }
        }
    }
    
    func bluetoothManager(_ aManager: BluetoothManager, didConnectPeripheral aPeripheral: CameraPeripheral) {
        isDeviceConnected = true;
        showAlert = false;
    }
    
    func bluetoothManager(_ aManager: BluetoothManager, didDisconnectPeripheral aPeripheral: CameraPeripheral) {
        isDeviceConnected = false;
        showAlert = true;
    }
    
}
    

