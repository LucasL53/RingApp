//
//  CameraPeripheral.swift
//  Ring Project
//
//  Created by Yunseo Lee on 7/16/23.
//

import UIKit
import CoreBluetooth

enum ImageServiceCommand: UInt8 {
    case noCommand          = 0x00
    case startSingleCapture = 0x01
    case startStreaming     = 0xB1 // I am guessin this is what cameraStartValue is?
    case stopStreaming      = 0x03
    case changeResolution   = 0x04
    case changePhy          = 0x05
    case sendBleParameters  = 0x06
    
    func data() -> Data {
        return Data([self.rawValue])
    }
}

enum InfoResponse: UInt8 {
    case unknown = 0x00
    case imgInfo = 0x01
    case bleInfo = 0x02
}

enum ImageResolution: UInt8 {
    case resolution160x120   = 0x01
    case resolution320x240   = 0x02
    case resolution640x480   = 0x03
    case resolution800x600   = 0x04
    case resolution1024x768  = 0x05
    case resolution1600x1200 = 0x06
    
    func description() -> String {
        switch self {
            case .resolution160x120:
                return "160x120"
            case .resolution320x240:
                return "320x240"
            case .resolution640x480:
                return "640x480"
            case .resolution800x600:
                return "800x600"
            case .resolution1024x768:
                return "1024x768"
            case .resolution1600x1200:
                return "1600x1200"
        }
    }
}

enum PhyType: UInt8 {
    case phyLE1M   = 0x01
    case phyLE2M   = 0x02
    
    func description() -> String {
        switch self {
            case .phyLE1M:
                return "LE 1M"
            case .phyLE2M:
                return "LE 2M"
        }
    }
}

class CameraPeripheral: NSObject, CBPeripheralDelegate, Identifiable {
    //MARK: - Service Identifiers
//    public static let imageServiceUUID            = CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA3E")
//    public static let imageRXCharacteristicUUID   = CBUUID(string: "6E400002-B5A3-F393-E0A9-E50E24DCCA3E")
//    public static let imageTXCharacteristicUUID   = CBUUID(string: "6E400003-B5A3-F393-E0A9-E50E24DCCA3E")
//    public static let imageInfoCharacteristicUUID = CBUUID(string: "6E400004-B5A3-F393-E0A9-E50E24DCCA3E")
    
    public static let banjiServiceUUID            = CBUUID(string: "47ea1400-a0e4-554e-5282-0afcd3246970")
    public static let cameraDataCharUUID          = CBUUID(string: "47ea1402-a0e4-554e-5282-0afcd3246970")
    public static let controlCharUUID             = CBUUID(string: "47ea1403-a0e4-554e-5282-0afcd3246970")
    // Do we have an info characteristics?
    
    //MARK: - Banji ID
    public static let cameraStartValue: UInt8 = 0xB1
    
    //MARK: - Banji Camera Buffer
    var cameraBuffer : [UInt8] = []
    
    //MARK: - Properties
    var targetPeripheral                : CBPeripheral
    var delegate                        : CameraPeripheralDelegate?
//    private var imageInfoCharacteristic : CBCharacteristic!
//    private var imageRXCharacteristic   : CBCharacteristic!
//    private var imageTXCharacteristic   : CBCharacteristic!
    
    private var bluetoothManager: BluetoothManager = BluetoothManager()
    
    private var cameraDataCharacteristics   : CBCharacteristic!
    private var cameraControlCharacteristics: CBCharacteristic!
    
    private var snapshotData            : Data         = Data()
    private var currentImageSize        : Int          = 0
    
//    private var imageStartTime          : TimeInterval = 0
//    private var imageElapsedTime        : TimeInterval = 0
//    private var streamStartTime         : TimeInterval = 0
    private var transferRate            : Double       = 0
    private var framesCount             : Int          = 0
    
    required init(withPeripheral aPeripheral: CBPeripheral) {
        targetPeripheral = aPeripheral
        super.init()
        targetPeripheral.delegate = self
    }

    public func basePeripheral() -> CBPeripheral {
        return targetPeripheral
    }
    
    //MARK: - ImageService API
    public func getBleParameters() {
        // Check if we need to write value of ble parameters to cameraDataCharacteristics
        targetPeripheral.writeValue(ImageServiceCommand.sendBleParameters.data(), for: cameraControlCharacteristics, type: .withoutResponse)
    }

    public func changePhy(_ aPhy: PhyType) {
        var changePhyCommand = ImageServiceCommand.changePhy.data()
        //The Raw value is decremented because phy command takes 0 for Phy1 and 1 for Phy2
        //However, the reported values in the ble connection info update will be 1 for Phy1 and 2 for Phy2
        //So the change phy command is offset by 1 to compensate.
        //See: https://github.com/NordicPlayground/nrf52-ble-image-transfer-demo/blob/master/main.c#L905
        changePhyCommand.append(contentsOf: [aPhy.rawValue - 1])
        targetPeripheral.writeValue(changePhyCommand, for: cameraControlCharacteristics, type: .withoutResponse)
    }
    
    public func changeResolution(_ aResolution : ImageResolution) {
        var changeResolutionCommand = ImageServiceCommand.changeResolution.data()
        changeResolutionCommand.append(contentsOf: [aResolution.rawValue])
        targetPeripheral.writeValue(changeResolutionCommand, for: cameraControlCharacteristics, type: .withoutResponse)
    }

    public func stopStream() {
        snapshotData = Data()
        targetPeripheral.writeValue(ImageServiceCommand.stopStreaming.data(), for: cameraControlCharacteristics, type: .withoutResponse)
    }

    public func startStream() {
//        streamStartTime = Date().timeIntervalSince1970
        framesCount = 0
        snapshotData = Data()
        targetPeripheral.writeValue(ImageServiceCommand.startStreaming.data(), for: cameraControlCharacteristics, type: .withoutResponse)
    }
    
    public func takeSnapshot() {
//        streamStartTime = Date().timeIntervalSince1970
        framesCount = 0
        snapshotData = Data()
        targetPeripheral.writeValue(ImageServiceCommand.startSingleCapture.data(), for: cameraControlCharacteristics, type: .withoutResponse)
    }
    
    //MARK: - Bluetooth API
    public func discoverServices() {
        targetPeripheral.discoverServices([CameraPeripheral.banjiServiceUUID])
    }
    
    public func enableNotifications() {
        guard cameraDataCharacteristics != nil else {
            return
        }
        targetPeripheral.setNotifyValue(true, for: cameraDataCharacteristics)
    }

    //MARK: - CBPeripheralDelegate
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else {
            delegate?.cameraPeripheral(self, failedWithError: error!)
            return
        }
        
        guard let services = peripheral.services else { return }
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service) // unsafe no specific UUID checking
        }
        
//        if let services = peripheral.services {
//            // Check if the required service has been found
//            guard services.count == 1 else {
//                delegate?.cameraPeripheralNotSupported(self)
//                return
//            }
//            
//            // If the service was found, discover required characteristics
//            for aService in services {
//                if aService.uuid == CameraPeripheral.banjiServiceUUID {
//                    peripheral.discoverCharacteristics([CameraPeripheral.controlCharUUID,
//                                                        CameraPeripheral.cameraDataCharUUID,
//                                                        CameraPeripheral.imageInfoCharacteristicUUID],
//                                                       for: aService)
//                }
//            }
//        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil else {
            delegate?.cameraPeripheral(self, failedWithError: error!)
            return
        }
        
        let thisBanji = (peripheral.identifier == self.targetPeripheral.identifier) ? "banji" : "unknown"
        print("\(thisBanji) characteristics:")
        if let characteristics = service.characteristics {
            // Assign references
            for aCharacteristic in characteristics {
                print(aCharacteristic)
                
                // how are we certain it is the right characteristic?
                if (thisBanji == "banji") {
                    cameraControlCharacteristics = aCharacteristic
                    
//                    if aCharacteristic.uuid == CameraPeripheral.cameraDataCharUUID {
//                        cameraDataCharacteristics = aCharacteristic
//                    } else if aCharacteristic.uuid == CameraPeripheral.controlCharUUID {
//                        cameraControlCharacteristics = aCharacteristic
//                    }
                }
            }
            
            // Check if all required characteristics were found
            guard cameraDataCharacteristics != nil && cameraControlCharacteristics != nil else {
                delegate?.cameraPeripheralNotSupported(self)
                return
            }
            
            // Notify the delegate that the device is supported and ready
            delegate?.cameraPeripheralDidBecomeReady(self)
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            delegate?.cameraPeripheral(self, failedWithError: error!)
            return
        }
        
        guard let value = characteristic.value else { return }
        let packetLength = Int(value.count)
        
        if characteristic == cameraControlCharacteristics {
            let dataPointer = UnsafeMutablePointer<UInt8>.allocate(capacity: 1)
            value.copyBytes(to: dataPointer, count: 1)
            if (dataPointer[0] == 0xFF) {
                bluetoothManager.connectionIntervalUpdated += 1
                print("Control interval updated")
                if (bluetoothManager.connectionIntervalUpdated == 1) {
                    startStream()
                }
            }
            
//            snapshotData.removeAll()
//            let data = characteristic.value!
//            let messageType = InfoResponse(rawValue: data[0]) ?? .unknown
//            switch messageType {
//            case .imgInfo:
//                imageStartTime   = Date().timeIntervalSince1970
//                transferRate     = 0
//                currentImageSize = data.subdata(in: 1..<5).withUnsafeBytes { (pointer: UnsafeRawBufferPointer) -> Int in
//                    let intPointer = pointer.bindMemory(to: Int.self)
//                    return intPointer.first ?? 0
//                }
//
//            case .bleInfo:
//                let mtuSize = data.subdata(in: 1..<3).withUnsafeBytes { (pointer: UnsafeRawBufferPointer) -> UInt16 in
//                    let uint16Pointer = pointer.bindMemory(to: UInt16.self)
//                    return uint16Pointer.first ?? 0
//                }
//                let connectionInterval = data.subdata(in: 3..<5).withUnsafeBytes { (pointer: UnsafeRawBufferPointer) -> Float in
//                    let uint16Pointer = pointer.bindMemory(to: UInt16.self)
//                    return Float(uint16Pointer.first ?? 0) * 1.25
//                }
//
//                
//                //Phy types here will be the UInt8 value 1 or 2 for 1Mb and 2Mb respectively.
//                let txPhy = PhyType(rawValue: data[5]) ?? .phyLE1M
//                let rxPhy = PhyType(rawValue: data[6]) ?? .phyLE1M
//                delegate?.cameraPeripheral(self, didUpdateParametersWithMTUSize: mtuSize, connectionInterval: connectionInterval, txPhy: txPhy, andRxPhy: rxPhy)
//            default:
//                break
//            }
        } else if characteristic == cameraDataCharacteristics {
            
            value.withUnsafeBytes{ (bufferRawBufferPointer) -> Void in
                
                let bufferPointerUInt8 = UnsafeBufferPointer<UInt8>.init(start: bufferRawBufferPointer.baseAddress!.bindMemory(to: UInt8.self, capacity: 1), count: packetLength)
                
                let sequenceNumberBytes : [UInt8] = [bufferRawBufferPointer[1], bufferRawBufferPointer[0]]
                
                let actualSequenceNumber = sequenceNumberBytes.withUnsafeBytes{$0.load(as: UInt16.self)}
                
                if (peripheral.identifier == self.targetPeripheral.identifier) {
                    
                    // Nominal behavior
                    // Packet format

                    // 0: Sequence Number
                    // 1: Status (IMU Valid: 1, Camera Valid:1)
                    // 2-3: Accel X
                    // 4-5: Accel Y
                    // 6-7: Accel Z
                    // 8-9: Gyro X
                    // 10-11: Gyro Y
                    // 12-13: Gyro Z
                    // 14-xxx: Camera

                    // This is going to be our packet format — since we’re not streaming the IMU yet, we start at 14 and just print. This is where we should drop this into an image.

                    // Byte 1 is going to be 8 bit of flags. In the future I can set a bit that says that it’s the end of the image or the start of the image.

                    // We should have 2 image buffers on the phone side. One for the current image being shown, and the other is receiving the next image. When the second buffer is filled, we should either swap, or update the image being shown to the second buffer. The next image that starts streaming should then get received in the original image, and so on.
                    
                    for i in 14...(packetLength - 1) {
                        cameraBuffer.append(bufferPointerUInt8[i])
                        print(bufferPointerUInt8[i], terminator:" ")
                    }
                    
                    print("") // ?
                    
                }
            }
            
//            if let dataChunk = characteristic.value {
//                snapshotData.append(dataChunk)
//            }
//            let now = Date().timeIntervalSince1970
//            imageElapsedTime = now - imageStartTime
//            transferRate     = Double(snapshotData.count) / imageElapsedTime * 8.0 / 1000.0 // convert bytes per second to kilobits per second
//            
//            if snapshotData.count == currentImageSize {
//                framesCount += 1
//                delegate?.cameraPeripheral(self, imageProgress: 1.0, transferRateInKbps: transferRate)
//                delegate?.cameraPeripheral(self, didReceiveImageData: snapshotData, withFps: Double(framesCount) / (now - streamStartTime))
//                snapshotData.removeAll()
//            } else {
//                let completion = Float(snapshotData.count) / Float(currentImageSize)
//                delegate?.cameraPeripheral(self, imageProgress: completion, transferRateInKbps: transferRate)
//            }
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            delegate?.cameraPeripheral(self, failedWithError: error!)
            return
        }
        if cameraDataCharacteristics.isNotifying {
            print("banji is streaming")
            delegate?.cameraPeripheralDidStart(self)
        }
    }
}
