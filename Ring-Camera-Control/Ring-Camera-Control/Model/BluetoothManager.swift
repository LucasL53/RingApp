//
//  BluetoothManager.swift
//  Ring-Camera-Control
//
//  Created by Yunseo Lee on 8/12/23.
//          Referenced a lot of code from Maruchi Kim
//          under his permission
//

import UIKit
import SwiftUI
import CoreBluetooth

//MARK: - Service Identifiers
let banjiServiceUUID            = CBUUID(string: "47ea1400-a0e4-554e-5282-0afcd3246970")
let cameraDataCharUUID          = CBUUID(string: "47ea1402-a0e4-554e-5282-0afcd3246970")
let controlCharUUID             = CBUUID(string: "47ea1403-a0e4-554e-5282-0afcd3246970")

enum ImageServiceCommand: UInt8 {
    case noCommand          = 0x00
    case startSingleCapture = 0x01
    case startStreaming     = 0xB1
    case stopStreaming      = 0x03
    case changeResolution   = 0x04
    case changePhy          = 0x05
    case sendBleParameters  = 0x06
    
    func data() -> Data {
        return Data([self.rawValue])
    }
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

class BluetoothManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate, ObservableObject {

    //MARK: - Properties
    let centralManager   : CBCentralManager
    var banji            : CBPeripheral!
    
    @Published var thisImage : Image?
    @Published var bluetoothStateString: String = "On Bluetooth"
    var discoveryHandler : ((CBPeripheral, NSNumber) -> ())?
    var connectionIntervalUpdated = 0
    
    private var cameraDataCharacteristics   : CBCharacteristic!
    private var cameraControlCharacteristics: CBCharacteristic!
    
    private var snapshotData            : Data         = Data()
    private var currentImageSize        : Int          = 0
    private var transferRate            : Double       = 0
    private var framesCount             : Int          = 0

    //MARK: - Banji Camera Buffer
    var cameraBuffer : [UInt8] = []

    //MARK: - Init
    required override init() {
        centralManager = CBCentralManager()
        super.init()
        centralManager.delegate = self
    }
    
    //MARK: - Bluetooth Functionalities
    
    public func enable() {
        let url = URL(string: UIApplication.openSettingsURLString) //for bluetooth setting
        let app = UIApplication.shared
        app.open(url!, options: [:], completionHandler: nil)
    }

    public func scanForPeripherals() {
        print("scan for peripherals ran")
        bluetoothStateString = "Off Bluetooth"
        guard centralManager.isScanning == false else {
            return // Return early if already scanning
        }
        centralManager.scanForPeripherals(withServices: nil, options: nil)
    }
    
    public func stopScan() {
        guard centralManager.isScanning else {
            return
        }
        bluetoothStateString = "On Bluetooth"
        centralManager.stopScan()
        discoveryHandler = nil
    }
    
    public func connection() {
        if banji.state != .connected {
            self.centralManager.connect(self.banji, options: nil)
        } else {
            centralManager.cancelPeripheralConnection(banji)
        }
    }
    
    public var state: CBManagerState {
        return centralManager.state
    }

    //MARK: - CBCentralManagerDelegate
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if(central.state == .poweredOn) {
            print("BLE powered on")
        } else {
            print("ERROR on BLE")
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices(nil)
        if (peripheral.identifier == self.banji.identifier) {
            print("Connected with banji \(peripheral.identifier)")
        }
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        connectionIntervalUpdated = (connectionIntervalUpdated > 0) ? (connectionIntervalUpdated - 1) : 0
        print("Disconnected with banji \(peripheral.identifier)")
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if let pname = peripheral.name {
            print("Discovered " + pname)
            if (pname == "banji") {
                self.banji = peripheral
                self.banji.delegate = self
                self.centralManager.connect(peripheral, options: nil)
                stopScan()
            }
        }
    }
    
    //MARK: - Camera Peripherals
    
    public func changeResolution(_ aResolution : ImageResolution) {
        var changeResolutionCommand = ImageServiceCommand.changeResolution.data()
        changeResolutionCommand.append(contentsOf: [aResolution.rawValue])
        banji.writeValue(changeResolutionCommand, for: cameraControlCharacteristics, type: .withoutResponse)
    }

    public func stopStream() {
        snapshotData = Data()
        banji.writeValue(ImageServiceCommand.stopStreaming.data(), for: cameraControlCharacteristics, type: .withoutResponse)
    }

    public func startStream() {
//        streamStartTime = Date().timeIntervalSince1970
        print("startStream ran")
        framesCount = 0
        snapshotData = Data()
        banji.setNotifyValue(true, for: cameraDataCharacteristics)
        banji.writeValue(ImageServiceCommand.startStreaming.data(), for: cameraControlCharacteristics, type: .withoutResponse)
    }
    
    public func takeSnapshot() {
//        streamStartTime = Date().timeIntervalSince1970
        framesCount = 0
        snapshotData = Data()
        banji.writeValue(ImageServiceCommand.startSingleCapture.data(), for: cameraControlCharacteristics, type: .withoutResponse)
    }
    
    
    //MARK: - Bytes to Image
    
    func createImageFromUInt8Buffer(buffer: [UInt8], width: Int, height: Int) -> UIImage? {
        // Check if the buffer size matches the width and height
        guard buffer.count == width * height else { return nil }
        // Create a bitmap context using the buffer data
        let colorSpace = CGColorSpaceCreateDeviceGray()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)
        let context = CGContext(data: UnsafeMutableRawPointer(mutating: buffer),
                                width: width,
                                height: height,
                                bitsPerComponent: 8,
                                bytesPerRow: width,
                                space: colorSpace,
                                bitmapInfo: bitmapInfo.rawValue)
        // Check if the context was created successfully
        guard let cgImage = context?.makeImage() else { return nil }
        // Create a UIImage from the CGImage
        let image = UIImage(cgImage: cgImage)
        return image
    }
    
    func updateImage(image: Image) {
        self.thisImage = image
    }
    
    //MARK: - CBPeripheralDelegate
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else {
            return
        }
        
        guard let services = peripheral.services else { return }
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil else {
            return
        }
        
        let thisBanji = (peripheral.identifier == banji.identifier) ? "banji" : "unknown"
        print("\(thisBanji) characteristics:")
        if let characteristics = service.characteristics {
            // Assign references
            for aCharacteristic in characteristics {
//                print(aCharacteristic)
                if (thisBanji == "banji") {
                    if aCharacteristic.uuid == controlCharUUID {
                        cameraControlCharacteristics = aCharacteristic
                        self.banji.setNotifyValue(true, for: cameraControlCharacteristics)
                    } else if aCharacteristic.uuid == cameraDataCharUUID {
                        cameraDataCharacteristics = aCharacteristic
                    }
                }
            }
            
            // Check if all required characteristics were found
            guard cameraDataCharacteristics != nil && cameraControlCharacteristics != nil else {
                return
            }
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            return
        }
        
        guard let value = characteristic.value else { return }
        let packetLength = Int(value.count)
//        print("Packet Length: ", packetLength)
        
        if characteristic == cameraControlCharacteristics {
            let dataPointer = UnsafeMutablePointer<UInt8>.allocate(capacity: 1)
            value.copyBytes(to: dataPointer, count: 1)
            
            if (dataPointer[0] == 0xFF) {
                connectionIntervalUpdated += 1
                print("Control interval updated")
                
                if (connectionIntervalUpdated == 1) {
                    startStream()
                }
            }
        } else if characteristic == cameraDataCharacteristics {
            
            value.withUnsafeBytes{ (bufferRawBufferPointer) -> Void in
                let bufferPointerUInt8 = UnsafeBufferPointer<UInt8>.init(start: bufferRawBufferPointer.baseAddress!.bindMemory(to: UInt8.self, capacity: 1), count: packetLength)
                let sequenceNumberBytes : [UInt8] = [bufferRawBufferPointer[1], bufferRawBufferPointer[0]]
                let actualSequenceNumber = sequenceNumberBytes.withUnsafeBytes{$0.load(as: UInt16.self)}
                
                if (peripheral.identifier == self.banji.identifier) {
                    
                    
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
                    
                    let imgWidth = 240
                    let imgHeight = 239
                    
                    if (bufferPointerUInt8[1] == 1) {
//                        let date = Date()
//                        let milliseconds = Int(date.timeIntervalSince1970 * 1000)
//                        print(milliseconds)
                        cameraBuffer.removeAll()
                    }
                    
                    for i in 14...(packetLength - 1) {
                        cameraBuffer.append(bufferPointerUInt8[i])
                        if (cameraBuffer.count % (imgWidth*imgHeight) == 0) {
                            if let uiImage = createImageFromUInt8Buffer(buffer: cameraBuffer, width: imgWidth, height: imgHeight) {
                                let image = Image(uiImage: uiImage)
                                DispatchQueue.main.async {
                                    self.updateImage(image: image)
                                }
                                print("image received")
                            } else {
                                print("error creating image from buffer")
                            }
                        }
                    }
                }
            }
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            return
        }
        if cameraControlCharacteristics.isNotifying && !cameraDataCharacteristics.isNotifying{
            print("banji is ready for stream")
        } else if cameraControlCharacteristics.isNotifying && cameraDataCharacteristics.isNotifying {
            print("banji is streaming")
        }
    }
}
