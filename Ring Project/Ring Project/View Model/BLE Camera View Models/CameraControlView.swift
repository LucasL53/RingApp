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
    @State private var cameraPeripheral: CameraPeripheral?
    @State private var isStreaming       : Bool              = false
    @State private var currentResolution : ImageResolution   = .resolution160x120
    @State private var currentPhy        : PhyType           = .phyLE1M
    @State private var isDeviceConnected = false;
    @State private var showAlert = false;
    @State private var imageData : UIImage?
    @State private var bluetoothStatus: String = "Bluetooth Off"
    var body: some View {
        ZStack (alignment: .topLeading) {
            Image(uiImage: imageData ?? UIImage(ciImage: .black))
                .frame(width: 100, height: 50)
                .padding()
                .background(.gray)
            Button(action: {
                setup()
            }){
                Text(bluetoothStatus)
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
                if (aPeripheral.name == "Test" && cameraPeripheral == nil) {
                    self.cameraPeripheral = CameraPeripheral(withPeripheral: aPeripheral)
                    if (self.cameraPeripheral == nil) {
                        print("Error finding peripheral")
                        return
                    }
                    self.cameraPeripheral?.delegate = self
                    bluetoothManager.connect(peripheral: self.cameraPeripheral!)
                    self.cameraPeripheralDidBecomeReady(self.cameraPeripheral!)
                    self.cameraPeripheral?.startStream()
                    bluetoothStatus = "Bluetooth On"
                }
            })
        }
        else {
            cameraPeripheral?.stopStream()
            bluetoothManager.disconnect()
        }
    }
}

extension CameraControlView: BluetoothManagerDelegate, CameraPeripheralDelegate {
    func cameraPeripheralDidBecomeReady(_ aPeripheral: CameraPeripheral) {
        aPeripheral.enableNotifications()
    }
    
    func cameraPeripheralNotSupported(_ aPeripheral: CameraPeripheral) {
        print("Not supported Camera")
    }
    
    func cameraPeripheralDidStart(_ aPeripheral: CameraPeripheral) {
        aPeripheral.getBleParameters()
    }
    
    func cameraPeripheral(_ aPeripheral: CameraPeripheral, failedWithError error: Error) {
        print("failed with error")
    }
    
    func cameraPeripheral(_ aPeripheral: CameraPeripheral, didReceiveImageData someData: Data, withFps fps: Double) {
        print("image data received")
        if let someImage = UIImage(data: someData) {
            imageData = someImage
        }
    }
    
    func cameraPeripheral(_ aPeripheral: CameraPeripheral, imageProgress: Float, transferRateInKbps: Double) {
        print("loading...")
    }
    
    func cameraPeripheral(_ aPeripheral: CameraPeripheral, didUpdateParametersWithMTUSize mtuSize: UInt16, connectionInterval connInterval: Float, txPhy: PhyType, andRxPhy rxPhy: PhyType) {
        if rxPhy == .phyLE1M && currentPhy == .phyLE2M {
            print("2mbps not supported")
            currentPhy = .phyLE1M
        }
        if rxPhy == .phyLE2M && currentPhy == .phyLE1M {
            print("Changing back to PHY LE 1M not supported")
            currentPhy = .phyLE2M
        }
    }
    
    func bluetoothManager(_ aManager: BluetoothManager, didUpdateState state: CBManagerState) {
        if state != .poweredOn {
            print("Bluetooth Not On")
            if (cameraPeripheral != nil) {
                bluetoothManager(aManager, didDisconnectPeripheral: cameraPeripheral!)
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
    

