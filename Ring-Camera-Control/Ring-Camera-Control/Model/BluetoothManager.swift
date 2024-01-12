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
    @ObservedObject var homeModel : HomeStore
    
    let centralManager   : CBCentralManager
    var banji            : CBPeripheral!
    
    
    @Published var banjiStatus : String = "disconnected"
    @Published var thisImage : Image?
    @Published var prediction: UUID?
    var discoveryHandler : ((CBPeripheral, NSNumber) -> ())?
    var connectionIntervalUpdated = 0
    var scanStatus  :  Bool = false
    
    private var cameraDataCharacteristics   : CBCharacteristic!
    private var cameraControlCharacteristics: CBCharacteristic!
    
    private var snapshotData            : Data         = Data()
    private var currentImageSize        : Int          = 0
    private var transferRate            : Double       = 0
    private var framesCount             : Int          = 0
    private var prevTimestamp           : Double       = 0.0
    private var classifiedDevice        : Int          = 0
    private var lastActionTimeMs        : Int          = 0
    private var prevButtonPressed       : Bool         = false
    private var saveImageFlag           : Bool         = false
    private var buttonPressedFlag       : Bool         = false
    private var controlDeviceFlag       : Bool         = false
    private var rotationInitialized     : Bool         = false
    private let date = Date()
    
    // This must align with MLHandler
    private let identifiers = ["69D467F4-2959-55C0-8DD3-C83B89A84FD2", "Blinds", "9CF6BB71-C066-5C6E-924E-994BCA7041E2", "Speaker", "TV"]
    
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
    let GRAVITY_REFERENCE_VECTOR: [Double] = [0.0,0.0,9.80665] // Vector representing gravity vector on earth (x,y,z)
        
    var rotationMatrix3D: [[Double]] = Array(repeating: Array(repeating: 0, count: 3), count: 3)
    
    var IMU_SAMPLE_PERIOD = 0.02 // 50 Hz sample rate
    
    // Initial Tilt on first button press
    var accelX_init: Double = 0.0
    var accelY_init: Double = 0.0
    var accelZ_init: Double = 0.0
    
    var accelX_float: Double = 0.0
    var accelY_float: Double = 0.0
    var accelZ_float: Double = 0.0
    
    var tiltX_init: Double = 0.0
    var tiltY_init: Double = 0.0
    var tiltZ_init: Double = 0.0
    
    var tiltXBuffer: [Double] = []
    var tiltYBuffer: [Double] = []
    var tiltZBuffer: [Double] = []
    
    var deltaXSum: Double = 0.0
    var deltaYSum: Double = 0.0
    var tiltXPrev: Double = 0.0
    var tiltYPrev: Double = 0.0
    
    //MARK: - Init
    required override init() {
        centralManager = CBCentralManager()
        mlModel = MLHandler()
        self.homeModel = HomeStore()
        super.init()
        centralManager.delegate = self
    }
    
    public func setHomeStore(homeStore: HomeStore) {
        self.homeModel = homeStore
        print("Updated Home Store in BLE Manager")
    }
    
    //MARK: - Bluetooth Functionalities
    public func enable() {
        let url = URL(string: UIApplication.openSettingsURLString) //for bluetooth setting
        let app = UIApplication.shared
        app.open(url!, options: [:], completionHandler: nil)
    }
    
    public func scanForPeripherals() {
        print("scan for peripherals ran")
        self.banjiStatus = "scanning"
        guard centralManager.isScanning == false else {
            return // Return early if already scanning
        }
        centralManager.scanForPeripherals(withServices: nil, options: nil)
        
    }
    
    public func stopScan() {
        guard centralManager.isScanning else {
            return
        }
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
            self.banjiStatus = "connected"
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
        self.banjiStatus = "disconnected"
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if let pname = peripheral.name {
            if (pname != "LG" && pname != "M108FP4") {
                //print("Discovered " + pname)
                if (pname == "banji") {
                    self.banji = peripheral
                    self.banji.delegate = self
                    self.centralManager.connect(peripheral, options: nil)
                    stopScan()
                }
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
    
    func convertBufferTo2DArray(buffer: [UInt8], width: Int, height: Int) -> [[UInt8]] {
        var array2D = [[UInt8]](repeating: [UInt8](repeating: 0, count: width), count: height)
        for y in 0..<height {
            for x in 0..<width {
                array2D[y][x] = buffer[y * width + x]
            }
        }
        return array2D
    }

    func convertBufferTo2DArrayDouble(buffer: [UInt8], width: Int, height: Int) -> [[Double]] {
        var array2D = [[Double]](repeating: [Double](repeating: 0, count: width), count: height)
        for y in 0..<height {
            for x in 0..<width {
                array2D[y][x] = Double(buffer[y * width + x])
            }
        }
        return array2D
    }

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
                    // 0: Sequence Number
                    // 1: Status (0: Start of Frame, 1: buttonPressed, 2: imuValid)
                    // 2-3: Accel X
                    // 4-5: Accel Y
                    // 6-7: Accel Z
                    // 8-9: Gyro X
                    // 10-11: Gyro Y
                    // 12-13: Gyro Z
                    // 14-xxx: Camera
                    
                    // let imgWidth = 128

                    let imgWidth = 162

                    let statusByte = bufferPointerUInt8[1]
                    let startOfFrame = (statusByte & 1) == 1
                    let buttonPressed = ((statusByte >> 1) & 1) == 1
                    let imuValid = ((statusByte >> 2) & 1) == 1

                    if (startOfFrame) {
                        let interval = CFAbsoluteTimeGetCurrent() - self.prevTimestamp
                        prevTimestamp = CFAbsoluteTimeGetCurrent()
                        
                        let imgHeight = self.cameraBuffer.count / imgWidth
                        
                        var extraSampleCount = cameraBuffer.count % imgWidth
                        cameraBuffer.removeLast(extraSampleCount)
                        
                        if let uiImage = createImageFromUInt8Buffer(buffer: cameraBuffer, width: imgWidth, height: imgHeight) {
                            if (saveImageFlag || buttonPressedFlag) {
                                // Save image on either iOS UI button press or ring hardware button press
                                print("Saving image to photo library")
                                UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
                                saveImageFlag = false
                            }
                            let image = Image(uiImage: uiImage)
                            DispatchQueue.main.async {
                                self.updateImage(image: image)
                            }
                            
                            if let cvpixelbuffer = createGrayScalePixelBuffer(image: uiImage, width: imgWidth, height: imgHeight) {
                                if let resized = resize(pixelBuffer: cvpixelbuffer, width: 160, height: 128) {
                                    let startTime = CFAbsoluteTimeGetCurrent() // Capture start time
                                    
                                    //classifiedDevice = mlModel.predict(image: resized)
                                    
                                    let endTime = CFAbsoluteTimeGetCurrent() // Capture end time
                                    let timeElapsed = endTime - startTime
                                    //print("prediction_time_ms: \(1000*timeElapsed)")
                                    if (buttonPressedFlag) {
                                        print("Arming controlDeviceFlag")
                                        controlDeviceFlag = true
                                    }
                                }
                                
                                //print("Received image " + "bufferCount:" + String(cameraBuffer.count) + " buttonPressed: " + String(statusByte >> 1) + " fps: " + String(Float(1 / interval) ))
                                
                            } else {
                                print("error creating cvpixelbuffer")
                            }
                        } else {
                            print("error creating image from buffer")
                        }
                        cameraBuffer.removeAll()
                    } // startOfFrame end
                    
                    
//                    if (controlDeviceFlag) {
//                        // Lights
//                        if (classifiedDevice == 0) {
//                            print("Controlling lights!")
//                            let optionalUUID: UUID? = UUID(uuidString:identifiers[classifiedDevice])
//                            if let unwrappedUUID = optionalUUID {
//                                homeModel.toggleAccessory(accessoryIdentifier: unwrappedUUID)
//                            } else {
//                                // Handle the case where optionalUUID is nil
//                                print("Failed to unwrap UUID")
//                            }
//                        } else if (classifiedDevice == 2) {
//                            print("Controlling Lock!")
//                            let optionalUUID: UUID? = UUID(uuidString:identifiers[classifiedDevice])
//                            if let unwrappedUUID = optionalUUID {
//                                homeModel.toggleAccessory(accessoryIdentifier: unwrappedUUID)
//                            } else {
//                                // Handle the case where optionalUUID is nil
//                                print("Failed to unwrap UUID")
//                            }
//                        }
//                    } // deviceControl end
                    

                    // Single Press Gesture

                    if (buttonPressed && (prevButtonPressed == false)) {
                        print("First button press")
                        let currentTimeMs = Int(CFAbsoluteTimeGetCurrent() * 1000)

                        //print ("currentTimeMs:" + String(currentTimeMs) + " lastActionTimeMs:" + String(self.lastActionTimeMs))
                        if (currentTimeMs - self.lastActionTimeMs > 500) {
                            // 500ms debounce
                            self.lastActionTimeMs = Int(CFAbsoluteTimeGetCurrent() * 1000)
                            print("Button down")
                            buttonPressedFlag = true
                        }
                    } // End of Single Press Gesture
                    
                    if (!buttonPressed) {
                        rotationInitialized = false
                    }

                    
                    if ((buttonPressed == false) && (controlDeviceFlag == true)) {
                        buttonPressedFlag = false
                        controlDeviceFlag = false
                    }

                    // TILT CODE START
                    // Establish Rotation Matrix
                    if (imuValid && !rotationInitialized && buttonPressed) {
                        // Get initial accelerometer vectors
                        accelX_init = lsbToMps2((Int16(bufferPointerUInt8[3]) << 8) | Int16(bufferPointerUInt8[2]),2,16)
                        accelY_init = lsbToMps2((Int16(bufferPointerUInt8[5]) << 8) | Int16(bufferPointerUInt8[4]),2,16)
                        accelZ_init = lsbToMps2((Int16(bufferPointerUInt8[7]) << 8) | Int16(bufferPointerUInt8[6]),2,16)
                        
                        print("Initial Accel")
                        print(accelX_init, accelY_init, accelZ_init)
                        
                        // Build Accel vector
                        let accelVector_init = [accelX_init, accelY_init, accelZ_init]

                        // Rotate entire 3D coordinate to align to [0,0,9.8] (x,y,z)
                        rotationMatrix3D = rotationMatrix(fromVector: accelVector_init, toVector: GRAVITY_REFERENCE_VECTOR)
                        
                        // Apply rotation to 0 out axes
                        var rotatedVectorInit = applyRotationMatrix(matrix: rotationMatrix3D, toVector: accelVector_init)
                        accelX_init = rotatedVectorInit[0]
                        accelY_init = rotatedVectorInit[1]
                        accelZ_init = rotatedVectorInit[2]
                        print("Corrected Acel")
                        print(accelX_init, accelY_init, accelZ_init)

                        tiltX_init = atan(accelX_init / sqrt(pow(accelY_init,2) + pow(accelZ_init,2))) * 180 / Double.pi
                        tiltY_init = atan(accelY_init / sqrt(pow(accelX_init,2) + pow(accelZ_init,2))) * 180 / Double.pi
                        tiltZ_init = atan(sqrt(pow(accelX_init,2) + pow(accelY_init,2)) / accelZ_init) * 180 / Double.pi
                        
                        var string1 = String(format: "%.2f %.2f %.2f", tiltX_init, tiltY_init, tiltZ_init)
                        print("Initial tilt")
                        print(string1)
                        
                        deltaXSum = 0.0
                        deltaYSum = 0.0
                        tiltXPrev = tiltX_init
                        tiltYPrev = tiltY_init
                        
                        rotationInitialized = true
                    }
                    
                    // Update Rotation
                    if (buttonPressed && (prevButtonPressed == true) && imuValid && rotationInitialized) {
                        accelX_float = lsbToMps2((Int16(bufferPointerUInt8[3]) << 8) | Int16(bufferPointerUInt8[2]), 2, 16)
                        accelY_float = lsbToMps2((Int16(bufferPointerUInt8[5]) << 8) | Int16(bufferPointerUInt8[4]), 2, 16)
                        accelZ_float = lsbToMps2((Int16(bufferPointerUInt8[7]) << 8) | Int16(bufferPointerUInt8[6]), 2, 16)
                        
//                        // Build Accel Vector
                        let accelerometerReadings: [Double] = [accelX_float, accelY_float, accelZ_float]  // Replace with your actual readings
                        
                        // Rotate entire 3D coordinate to align to [0,0,9.8] (x,y,z)
                        var rotationMatrix: [[Double]] = [  [1.0000000,  0.0000000,  0.0000000],
                                                            [0.0000000,  0.1673408,  0.9858991],
                                                            [0.0000000, -0.9858991,  0.1673408 ]]
                        var rotatedVector = applyRotationMatrix(matrix: rotationMatrix3D, toVector: accelerometerReadings)

                        accelX_float = rotatedVector[0]
                        accelY_float = rotatedVector[1]
                        accelZ_float = rotatedVector[2]
                        
//                        accelTilt.x = atan2(accelY_float, accelZ_float) * (180 / Double.pi)
//                        accelTilt.y = atan2(-1*accelX_float, sqrt(pow(accelY_float,2) + pow(accelZ_float, 2))) * (180 / Double.pi)
//                        accelTilt.z = atan2(accelX_float, accelY_float) * (180 / Double.pi)
//                        
                        accelTilt.x = atan(accelX_float / sqrt(pow(accelY_float,2) + pow(accelZ_float,2))) * 180 / Double.pi
                        accelTilt.y = atan(accelY_float / sqrt(pow(accelX_float,2) + pow(accelZ_float,2))) * 180 / Double.pi
                        accelTilt.z = atan(sqrt(pow(accelX_float,2) + pow(accelY_float,2)) / accelZ_float) * 180 / Double.pi
                        
                        deltaXSum += accelTilt.x - tiltXPrev
                        deltaYSum += accelTilt.y - tiltYPrev
                        
                        tiltXPrev = accelTilt.x
                        tiltYPrev = accelTilt.y
                        
                        var ratio = Double((1+(abs(self.deltaXSum))) / (1+abs(self.deltaYSum)))
                        var threshold = 9.0
                        
//                        if (ratio > threshold) {
//                            print("ROTATION")
//                        } else if ((1.0/ratio) > threshold) {
//                            print("UP/DOWN")
//                        }
//                        
                        if (abs(deltaXSum) >= 10) {
                            print("ROTATION")
                        }
                        
                        if (abs(deltaYSum) >= 10) {
                            print("UP/DOWN")
                        }
                        

                        var u_x = accelTilt.x / 90.0
                        var u_y = accelTilt.y / 90.0
                        var u_z = accelTilt.z / 90.0
                        
                        var mappedTilt = (u_x + u_y + u_z) / 3

                        var outputString1 = String(format: "x:%.2f y:%.2f z:%.2f | x:%.2f y:%.2f z:%.2f | %f", accelX_float, accelY_float, accelZ_float, accelTilt.x, accelTilt.y,accelTilt.z, mappedTilt)
                        print(outputString1)
                    }
                    
                    if (prevButtonPressed != buttonPressed) {
                        prevButtonPressed = buttonPressed
                        print("Update prevButtonWasPressed to", prevButtonPressed)
                    }
                    
                    for i in 14...(packetLength - 1) {
                        cameraBuffer.append(bufferPointerUInt8[i])
                    }
                }
            }
        }
    }
    
    public func savePicture()
    {
        print("Saving next picture")
        saveImageFlag = true
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
    
    // Apply the rotation using the rotation matrix
    public func applyRotationMatrix(matrix: [[Double]], toVector vector: [Double]) -> [Double] {
        
       
        var rotatedVector: [Double] = [0, 0, 0]
        
        for i in 0..<3 {
            for j in 0..<3 {
                rotatedVector[i] += matrix[i][j] * vector[j]
            }
        }
        
        return rotatedVector
    }
    
    // Function to calculate the cross product of two vectors
    func crossProduct(_ a: [Double], _ b: [Double]) -> [Double] {
        return [
            a[1] * b[2] - a[2] * b[1],
            a[2] * b[0] - a[0] * b[2],
            a[0] * b[1] - a[1] * b[0]
        ]
    }

    // Function to calculate the dot product of two vectors
    func dotProduct(_ a: [Double], _ b: [Double]) -> Double {
        return zip(a, b).map(*).reduce(0, +)
    }

    // Function to normalize a vector
    func normalize(_ vector: [Double]) -> [Double] {
        let magnitude = sqrt(dotProduct(vector, vector))
        return vector.map { $0 / magnitude }
    }

    // Function to calculate the rotation matrix to rotate vector a onto vector b
    func rotationMatrix(fromVector a: [Double], toVector b: [Double]) -> [[Double]] {
        // Normalize vectors
        let aNormalized = normalize(a)
        let bNormalized = normalize(b)
        
        // Calculate the axis of rotation (cross product of a and b)
        let axis = crossProduct(aNormalized, bNormalized)
        
        // Calculate the angle of rotation (dot product of a and b)
        let angle = acos(dotProduct(aNormalized, bNormalized))
        
        // Check if the vectors are already aligned
//        if angle.isNaN {
//            return nil // Vectors are already aligned
//        }
        
        // Create the rotation matrix
        let c = 1 - cos(angle)
        let s = sin(angle)
        let x = axis[0]
        let y = axis[1]
        let z = axis[2]
        
        let rotationMatrix: [[Double]] = [
            [cos(angle) + x * x * c, x * y * c - z * s, x * z * c + y * s],
            [y * x * c + z * s, cos(angle) + y * y * c, y * z * c - x * s],
            [z * x * c - y * s, z * y * c + x * s, cos(angle) + z * z * c]
        ]
        
        return rotationMatrix
    }

    func printMatrix(matrix: [[Double]]) {
        for i in 0..<matrix.count {
            for j in 0..<matrix[i].count {
                print(matrix[i][j], terminator: "\t")
            }
            print()
        }
    }


}
