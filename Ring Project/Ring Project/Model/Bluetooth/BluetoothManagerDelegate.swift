//
//  BluetoothManagerDelegate.swift
//  Ring Project
//
//  Created by Yunseo Lee on 7/16/23.
//

import CoreBluetooth

protocol BluetoothManagerDelegate {
    func bluetoothManager(_ aManager: BluetoothManager, didUpdateState state: CBManagerState)
    func bluetoothManager(_ aManager: BluetoothManager, didConnectPeripheral aPeripheral: CameraPeripheral)
    func bluetoothManager(_ aManager: BluetoothManager, didDisconnectPeripheral aPeripheral: CameraPeripheral)
}
