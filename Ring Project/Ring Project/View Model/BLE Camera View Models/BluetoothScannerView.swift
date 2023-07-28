//
//  BluetoothScannerView.swift
//  Ring Project
//
//  Created by Yunseo Lee on 7/16/23.
//

import SwiftUI
import CoreBluetooth

struct BluetoothScannerView: View {
    @ObservedObject var bluetoothManager: BluetoothManager
    @State private var peripherals: [CameraPeripheral] = []
    @State private var isScanning: Bool = false
    @State private var selectedPeripheral: CameraPeripheral?
    @State private var isBluetoothEnabled: Bool = false
    @State private var isConnected: Bool = false
    @State private var showCameraControl: Bool = false

    var body: some View {
        List {
            Section(header: sectionHeaderView()) {
                if peripherals.isEmpty {
                    Text("No targets")
                } else {
                    ForEach(peripherals) { peripheral in
                        Text(peripheral.basePeripheral().name ?? "No name")
                            .onTapGesture {
                                stopScan()
                                connect(to: peripheral)
                            }
                    }
                }
            }
        }
        .onAppear {
            bluetoothManager.delegate = self
            if bluetoothManager.state == .poweredOn {
                startScan()
            }
        }
    }
    
    private func sectionHeaderView() -> some View {
        VStack(alignment: .leading) {
            Text("Section Header")
                .font(.headline)
        }
    }

    private func startScan() {
        if isScanning {
            peripherals.removeAll()
        }
    }

    private func stopScan() {
        isScanning = false
        bluetoothManager.stopScan()
    }

    private func connect(to peripheral: CameraPeripheral) {
        // Connect to the peripheral
    }
    
    private func discoverServices(for aPeripheral: CameraPeripheral) {
        print("Discovering services...")
        aPeripheral.discoverServices()
    }
    
    private func startCamera(with aPeripheral: CameraPeripheral) {
        print("Ready")
        selectedPeripheral = aPeripheral
        showCameraControl = true
    }
}

extension BluetoothScannerView: BluetoothManagerDelegate {
    func bluetoothManager(_ aManager: BluetoothManager, didUpdateState state: CBManagerState) {
        if state == .poweredOn {
            isBluetoothEnabled = true
            startScan()
        } else {
            stopScan()
            isBluetoothEnabled = false
        }
    }
    
    func bluetoothManager(_ aManager: BluetoothManager, didConnectPeripheral aPeripheral: CameraPeripheral) {
        isConnected = true
        discoverServices(for: aPeripheral)
    }
    
    func bluetoothManager(_ aManager: BluetoothManager, didDisconnectPeripheral aPeripheral: CameraPeripheral) {
        isConnected = false
        startScan()
    }
}

extension BluetoothScannerView: CameraPeripheralDelegate {
    func cameraPeripheralDidBecomeReady(_ aPeripheral: CameraPeripheral) {
        startCamera(with: aPeripheral)
    }
    
    func cameraPeripheralNotSupported(_ aPeripheral: CameraPeripheral) {
        print("Device not supported")
    }
    
    func cameraPeripheral(_ aPeripheral: CameraPeripheral, failedWithError error: Error) {
        print("Error: \(error.localizedDescription)")
    }
    
    func cameraPeripheralDidStart(_ aPeripheral: CameraPeripheral) {
        //NOOP
    }
    
    func cameraPeripheral(_ aPeripheral: CameraPeripheral, didReceiveImageData someData: Data, withFps fps: Double) {
        //NOOP
    }
    
    func cameraPeripheral(_ aPeripheral: CameraPeripheral, imageProgress: Float, transferRateInKbps: Double) {
        //NOOP
    }
    
    func cameraPeripheral(_ aPeripheral: CameraPeripheral, didUpdateParametersWithMTUSize mtuSize: UInt16, connectionInterval connInterval: Float, txPhy: PhyType, andRxPhy rxPhy: PhyType) {
        //NOOP
    }
}
