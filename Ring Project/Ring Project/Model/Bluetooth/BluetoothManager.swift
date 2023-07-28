//
//  BluetoothManager.swift
//  Ring Project
//
//  Created by Yunseo Lee on 7/16/23.
//

import UIKit
import CoreBluetooth


class BluetoothManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate , ObservableObject {

    //MARK: - Properties
    let centralManager   : CBCentralManager
    var banji            : CBPeripheral!
    @Published var targetPeripheral : CameraPeripheral?
    var discoveryHandler : ((CBPeripheral, NSNumber) -> ())?
    var delegate         : BluetoothManagerDelegate?
    var connectionIntervalUpdated = 0
    

    required override init() {
        centralManager = CBCentralManager()
        super.init()
        centralManager.delegate = self
    }
    
    public func enable() {
        let url = URL(string: UIApplication.openSettingsURLString) //for bluetooth setting
        let app = UIApplication.shared
        app.open(url!, options: [:], completionHandler: nil)
    }

    public func scanForPeripherals() {
        print("scan for peripherals ran")
//        guard centralManager.isScanning == false else {
//            print("guard let passed")
//            return // Return early if already scanning
//        }
        centralManager.scanForPeripherals(withServices: nil, options: nil)
    }
    
    public func stopScan() {
        guard centralManager.isScanning else {
            return
        }
        centralManager.stopScan()
        discoveryHandler = nil
    }
    
    public func connect(peripheral: CameraPeripheral) {
        guard targetPeripheral == nil else {
            // A peripheral is already connected
            return
        }
        targetPeripheral = peripheral
        centralManager.connect(peripheral.basePeripheral(), options: nil)
    }
    
    public func disconnect() {
        guard targetPeripheral != nil else {
            // No device connected at the moment
            return
        }
        centralManager.cancelPeripheralConnection(targetPeripheral!.basePeripheral())
    }
    
    public var state: CBManagerState {
        return centralManager.state
    }

    //MARK: - CBCentralManagerDelegate
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        delegate?.bluetoothManager(self, didUpdateState: central.state)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices(nil) // what are we looking for here
        print("Connected with banji \(peripheral.identifier)")
        delegate?.bluetoothManager(self, didConnectPeripheral: targetPeripheral!)
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        delegate?.bluetoothManager(self, didDisconnectPeripheral: targetPeripheral!)
        targetPeripheral = nil
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        connectionIntervalUpdated = (connectionIntervalUpdated > 0) ? (connectionIntervalUpdated - 1) : 0
        print("Connected with banji \(peripheral.identifier)")
        delegate?.bluetoothManager(self, didDisconnectPeripheral: targetPeripheral!)
        targetPeripheral = nil
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if let pname = peripheral.name {
            print("Discovered " + pname)
            if (pname == "banji") {
                self.banji = peripheral
                self.targetPeripheral = CameraPeripheral(withPeripheral: self.banji)
                self.banji.delegate = self
                self.centralManager.connect(peripheral, options: nil)
            }
        }
    }
}

