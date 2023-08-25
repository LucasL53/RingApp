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
import CoreML
import CoreVideo

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
    var mlModel          : MLHandler
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
    private var prevTimestamp           : Int          = Int(1000)
    
    struct accelTilt {
        static var x: Double = 0.0
        static var y: Double = 0.0
        static var z: Double = 0.0
    }
            
    struct gyroTilt {
        static var x: Double = 0.0
        static var y: Double = 0.0
        static var z: Double = 0.0
    }
            
    struct fusedTilt {
        static var alpha: Double = 0.02
        static var x: Double = 0.0
        static var y: Double = 0.0
        static var z: Double = 0.0
    }

    //MARK: - Banji Camera Buffer
    var cameraBuffer : [UInt8] = []
    
    //MARK: - IMU Buffers
    var accelXBuffer: [Float] = []
    var accelYBuffer: [Float] = []
    var accelZBuffer: [Float] = []
    var gyroXBuffer: [Float] = []
    var gyroYBuffer: [Float] = []
    var gyroZBuffer: [Float] = []
    let GRAVITY_EARTH: Double = 9.80665
    
    //MARK: - Init
    required override init() {
        centralManager = CBCentralManager()
        mlModel = MLHandler()
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
    
    func createGrayScalePixelBuffer(image: UIImage, width: Int, height: Int) -> CVPixelBuffer? {
        let ciImage = CIImage(image: image)
        let filter = CIFilter(name: "CIColorControls")!
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(0, forKey: kCIInputSaturationKey) // Set saturation to 0 to get grayscale

        guard let outputImage = filter.outputImage else { return nil }

        let context = CIContext()
        let pixelBufferOptions: [String: Any] = [kCVPixelBufferCGImageCompatibilityKey as String: true,
                                                 kCVPixelBufferCGBitmapContextCompatibilityKey as String: true]

        var pixelBuffer: CVPixelBuffer? = nil
        let status = CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_OneComponent8, pixelBufferOptions as CFDictionary, &pixelBuffer)
        guard status == kCVReturnSuccess, let finalPixelBuffer = pixelBuffer else {
            return nil
        }

        let rect = CGRect(x: 0, y: 0, width: width, height: height)
        context.render(outputImage, to: finalPixelBuffer, bounds: rect, colorSpace: CGColorSpaceCreateDeviceGray())

        return finalPixelBuffer
    }
    
//    func createPixelBufferFromUInt8Buffer(buffer: [UInt8], width: Int, height: Int) -> CVPixelBuffer? {
//        // Check if the buffer size matches the width and height
//        guard buffer.count == width * height else { return nil }
//        
//        var pixelBuffer: CVPixelBuffer?
//        let status = CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_OneComponent8, nil, &pixelBuffer)
//        
//        guard status == kCVReturnSuccess else {
//            return nil
//        }
//        
//        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
//        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)
//        
//        memcpy(pixelData, buffer, buffer.count)
//        
//        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
//
//        return pixelBuffer
//    }

    func resize(pixelBuffer: CVPixelBuffer, width: Int, height: Int) -> CVPixelBuffer? {
        var maybePixelBuffer: CVPixelBuffer?
        CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32ARGB, nil, &maybePixelBuffer)
        guard let resizedPixelBuffer = maybePixelBuffer else { return nil }

        CVPixelBufferLockBaseAddress(resizedPixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        let resizedData = CVPixelBufferGetBaseAddress(resizedPixelBuffer)

        guard let context = CGContext(
            data: resizedData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(resizedPixelBuffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        ) else { return nil }

        let rect = CGRect(x: 0, y: 0, width: width, height: height)
        context.clear(rect)

        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let ciContext = CIContext(options: nil)
        guard let cgImage = ciContext.createCGImage(ciImage, from: rect) else { return nil }

        context.draw(cgImage, in: rect)

        CVPixelBufferUnlockBaseAddress(resizedPixelBuffer, CVPixelBufferLockFlags(rawValue: 0))

        return resizedPixelBuffer
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
    
    func lsbToMps2(_ val: Int16, _ gRange: Double, _ bitWidth: UInt8) -> Double {
        let power = 2.0
        
        let halfScale = Double(pow(Double(power), Double(bitWidth))) / 2.0
        
        return (Double(GRAVITY_EARTH) * Double(val) * gRange) / halfScale
    }
    
    func lsbToDps(_ val: Int16, _ dps: Double, _ bitWidth: UInt8) -> Double {
        let power = 2.0
        
        let halfScale = Double(pow(Double(power), Double(bitWidth))) / 2.0
        
        return (dps / halfScale) * Double(val)
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
                    
                    var imgWidth = 162
//                        var imgHeight = 119
                    let statusByte = bufferPointerUInt8[1]
                    let startOfFrame = (statusByte & 1) == 1
                    let buttonPressed = ((statusByte >> 1) & 1) == 1
                    if (startOfFrame) {
                        let date = Date()
                        let interval = Int(date.timeIntervalSince1970 * 1000) - self.prevTimestamp
                        prevTimestamp = Int(date.timeIntervalSince1970 * 1000)
                        
                        var imgHeight = self.cameraBuffer.count / imgWidth
                        
                        var extraSampleCount = cameraBuffer.count % imgWidth
                        cameraBuffer.removeLast(extraSampleCount)
                        
                        if let uiImage = createImageFromUInt8Buffer(buffer: cameraBuffer, width: imgWidth, height: imgHeight) {
                            let image = Image(uiImage: uiImage)
                            DispatchQueue.main.async {
                                self.updateImage(image: image)
                            }
                            if let cvpixelbuffer = createGrayScalePixelBuffer(image: uiImage, width: imgWidth, height: imgHeight) {
                                if let resized = resize(pixelBuffer: cvpixelbuffer, width: 162, height: 119) {
                                    let startTime = CFAbsoluteTimeGetCurrent() // Capture start time
                                    
                                    mlModel.predict(image: resized)
                                    
                                    let endTime = CFAbsoluteTimeGetCurrent() // Capture end time
                                    let timeElapsed = endTime - startTime
                                    print("Time taken for prediction: \(timeElapsed) seconds")
                                }
                                
                                print("Received image " + "bufferCount:" + String(cameraBuffer.count) + " buttonPressed: " + String(statusByte >> 1) + "fps: " + String(Float(1 / (Float(interval)/Float(1000)) )))
                                
                            } else {
                                print("error creating cvpixelbuffer")
                            }
                        } else {
                            print("error creating image from buffer")
                        }
                        cameraBuffer.removeAll()
                    } // startOfFrame end
                
                    var accelX = (Int16(bufferPointerUInt8[3]) << 8) | Int16(bufferPointerUInt8[2])
                    var accelY = (Int16(bufferPointerUInt8[5]) << 8) | Int16(bufferPointerUInt8[4])
                    var accelZ = (Int16(bufferPointerUInt8[7]) << 8) | Int16(bufferPointerUInt8[6])
                    var gyroX  = (Int16(bufferPointerUInt8[9])  << 8) | Int16(bufferPointerUInt8[8])
                    var gyroY  = (Int16(bufferPointerUInt8[11]) << 8) | Int16(bufferPointerUInt8[10])
                    var gyroZ  = (Int16(bufferPointerUInt8[13]) << 8) | Int16(bufferPointerUInt8[12])
                                      
                    var accelX_float = lsbToMps2(accelX, 2, 16)
                    var accelY_float = lsbToMps2(accelY, 2, 16)
                    var accelZ_float = lsbToMps2(accelZ, 2, 16)
                                       
                    var gyroX_float = lsbToDps(gyroX, 2000, 16)
                    var gyroY_float = lsbToDps(gyroY, 2000, 16)
                    var gyroZ_float = lsbToDps(gyroZ, 2000, 16)

                    accelXBuffer.append(Float(accelX_float))
                    accelYBuffer.append(Float(accelY_float))
                    accelZBuffer.append(Float(accelZ_float))
                    gyroXBuffer.append(Float(gyroX_float))
                    gyroYBuffer.append(Float(gyroY_float))
                    gyroZBuffer.append(Float(gyroZ_float))
                                       
                    accelTilt.x = atan(accelX_float / sqrt(pow(accelY_float,2) + pow(accelZ_float,2))) * 180 / Double.pi
                    accelTilt.y = atan(accelY_float / sqrt(pow(accelX_float,2) + pow(accelZ_float,2))) * 180 / Double.pi
                    accelTilt.z = atan(sqrt(pow(accelX_float,2) + pow(accelY_float,2)) / accelZ_float) * 180 / Double.pi
                      
                    gyroTilt.x += gyroX_float
                    gyroTilt.y += gyroY_float
                    gyroTilt.z += gyroZ_float
                                        
                    fusedTilt.x = (1 - fusedTilt.alpha) * (fusedTilt.x + gyroX_float) + (fusedTilt.alpha) * (accelTilt.x)
                    fusedTilt.y = (1 - fusedTilt.alpha) * (fusedTilt.y + gyroY_float) + (fusedTilt.alpha) * (accelTilt.y)
                                             
                    let aTilt = sqrt(pow(accelTilt.x, 2) + pow(accelTilt.y, 2))
                    let gTilt = sqrt(pow(gyroTilt.x, 2) + pow(gyroTilt.y, 2))
                    let fTilt = sqrt(pow(fusedTilt.x, 2) + pow(fusedTilt.y, 2))
                            
                    //let outputString = String(format: "Accel X Accel Y Accel Z Gyro X Gyro Y Gyro Z\n%.2f %.2f %.2f %.2f %.2f %.2f", accelX_float, accelY_float,accelZ_float, gyroX_float, gyroY_float, gyroZ_float)
                    let outputString = String(format: "aTile gTilt fTilt\n%.2f %.2f %.2f %.2f %.2f %.2f", aTilt, gTilt,fTilt, accelTilt.x,accelTilt.y, accelTilt.z)
                    print(outputString)
                    
                    for i in 14...(packetLength - 1) {
                        cameraBuffer.append(bufferPointerUInt8[i])
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
