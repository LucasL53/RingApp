//
//  HomeStore.swift
//  Ring-Camera-Control
//
//  Created by Yunseo Lee on 8/12/23.
//

import Foundation
import HomeKit

// overall access to the home network will only be done through the HomeStore
class HomeStore: NSObject, ObservableObject, HMHomeManagerDelegate {
    
    // To stay informed of any changes made on any of the Homes,
    // the HMHomeManagerDelegate Protocol communicates any changes in the state of the home network
    @Published var homes: [HMHome] = []
    @Published var accessories: [HMAccessory] = []
    @Published var services: [HMService] = []
    @Published var characteristics: [HMCharacteristic] = []
    private var manager: HMHomeManager!
    
    @Published var readingData: Bool = false // USE: disabling certain parts of the app's UI until the data has been successfully read and the UI has been updated.
    // Accessory Information
    var identify: String?
    var manufacturer: String?
    var modelName: String?
    var name: String?
    var serialNum: String?
    var FirmwareVer: String?
    
    // LightBulb Characteristics
    @Published var powerState: Bool?
    @Published var hueValue: Int?
    @Published var brightnessValue: Int?
    @Published var saturation: Int?
    
    // Window Characteristics
    @Published var currentPosition: Int?
    @Published var targetPosition: Int?
    @Published var positionState: Int? // This is close = 0 | opening = 1 | closing = 2
    @Published var holdPosition: Bool?
    @Published var obstructionDetected: Bool?
    // if Window Covering
    // @Published var currentHorizontalTiltAngle: Int?
    // @Published var targetHorizontalTiltAngle: Int?
    // @Published var currentVerticalTiltAngle: Int?
    // @Published var targetVerticalTiltAngle: Int?
    
    // Lock Mechanism
    @Published var lockCurrentState: HMCharacteristicValueLockMechanismState? // current using string to indicate Unsecured/Secured/Jammed/Unknown
    @Published var lockTargetState: Bool? // True/False for Secured/Unsecured respectively
    
    // Speaker
    @Published var mute: Bool?
    @Published var volume: Int?

    override init(){
        super.init()
        load()
    }
    
    func load() {
        if manager == nil {
            manager = .init()
            manager.delegate = self
        }
    }

    func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
        self.homes = self.manager.homes
    }
    
    func findAccessories(homeId: UUID) {
        guard let devices = homes.first(where: {$0.uniqueIdentifier == homeId})?.accessories else {
            print("ERROR: No Accessory not found!")
            return
        }
//        print(devices)
        accessories = devices
    }
    func findServices(accessoryId: UUID, homeId: UUID){
        guard let accessoryServices = homes.first(where: {$0.uniqueIdentifier == homeId})?.accessories.first(where: {$0.uniqueIdentifier == accessoryId})?.services else {
            print("ERROR: No Services found!")
            return
        }
        print(accessoryServices)
        services = accessoryServices
    }
    func findCharacteristics(serviceId: UUID, accessoryId: UUID, homeId: UUID){
        guard let serviceCharacteristics = homes.first(where: {$0.uniqueIdentifier == homeId})?.accessories.first(where: {$0.uniqueIdentifier == accessoryId})?.services.first(where: {$0.uniqueIdentifier == serviceId})?.characteristics else {
            print("ERROR: No Characteristics found!")
            return
        }
//        print(serviceCharacteristics)
        characteristics = serviceCharacteristics
    }
    
    func characteristicValue(for characteristic: HMCharacteristic) -> Any? {
        switch characteristic.localizedDescription {
        case "Power State":
            return powerState
        case "Hue":
            return hueValue
        case "Brightness":
            return brightnessValue
        case "Current Position":
            return currentPosition
        case "Target Position":
            return targetPosition
        case "Position State":
            return positionState
        case "Obstruction Detected":
            return obstructionDetected
        case "Lock Current State":
            return lockCurrentState
        case "Lock Target State":
            return lockTargetState
        case "Mute":
            return mute
        case "Volume":
            return volume
        default:
            return nil
        }
    }

    
    // Reading individual Characteristic to change
    func readCharacteristicValue(characteristicID: UUID?){
        guard let characteristicToRead = characteristics.first(where: {$0.uniqueIdentifier == characteristicID}) else {
            print("ERROR: Characteristic not found!")
            return
        }
        readingData = true
        characteristicToRead.readValue(completionHandler: {_ in
            switch characteristicToRead.localizedDescription {
            case "Power State":
                self.powerState = characteristicToRead.value as? Bool
            case "Hue":
                self.hueValue = characteristicToRead.value as? Int
            case "Brightness":
                self.brightnessValue = characteristicToRead.value as? Int
            case "Current Position":
                self.currentPosition = characteristicToRead.value as? Int
            case "Target Position":
                self.targetPosition = characteristicToRead.value as? Int
            case "Position State":
                self.positionState = characteristicToRead.value as? Int
            case "Obstruction Detected":
                self.obstructionDetected = characteristicToRead.value as? Bool
            case "Lock Current State":
                self.lockCurrentState = characteristicToRead.value as? HMCharacteristicValueLockMechanismState
            case "Lock Target State":
                self.lockTargetState = characteristicToRead.value as? Bool
            case "Mute":
                self.mute = characteristicToRead.value as? Bool
            case "Volume":
                self.volume = characteristicToRead.value as? Int
            case "Identify":
                self.identify = characteristicToRead.value as? String
            case "Manufacturer":
                self.manufacturer = characteristicToRead.value as? String
            case "Model":
                self.modelName = characteristicToRead.value as? String
            case "Serial Number":
                self.serialNum = characteristicToRead.value as? String
            case "Firmware Version":
                self.FirmwareVer = characteristicToRead.value as? String
            default:
                break
            }
            self.readingData = false
        })
    }
    
    // Reading new initial values of Charactersistics
    func readCharacteristicValues(serviceId: UUID){
        guard let characteristicsToRead = services.first(where: {$0.uniqueIdentifier == serviceId})?.characteristics else {
            print("ERROR: Characteristic not found!")
            return
        }
        readingData = true
        for characteristic in characteristicsToRead {
            characteristic.readValue(completionHandler: {_ in
                print("DEBUG: reading characteristic value: \(characteristic.localizedDescription)")
                switch characteristic.localizedDescription {
                case "Power State":
                    self.powerState = characteristic.value as? Bool
                case "Hue":
                    self.hueValue = characteristic.value as? Int
                case "Brightness":
                    self.brightnessValue = characteristic.value as? Int
                case "Current Position":
                    self.currentPosition = characteristic.value as? Int
                case "Target Position":
                    self.targetPosition = characteristic.value as? Int
                case "Position State":
                    self.positionState = characteristic.value as? Int
                case "Obstruction Detected":
                    self.obstructionDetected = characteristic.value as? Bool
                case "Lock Current State":
                    self.lockCurrentState = characteristic.value as? HMCharacteristicValueLockMechanismState
                case "Lock Target State":
                    self.lockTargetState = characteristic.value as? Bool
                case "Mute":
                    self.mute = characteristic.value as? Bool
                case "Volume":
                    self.volume = characteristic.value as? Int
                case "Identify":
                    self.identify = characteristic.value as? String
                case "Manufacturer":
                    self.manufacturer = characteristic.value as? String
                case "Model":
                    self.modelName = characteristic.value as? String
                case "Serial Number":
                    self.serialNum = characteristic.value as? String
                case "Firmware Version":
                    self.FirmwareVer = characteristic.value as? String
                default:
                    break
                }
                self.readingData = false
            })
        }
    }
    
    // MARK: - Characteristics Functionality
    
    // READ/SET CHARACTERISTICS
    func setCharacteristicValue(characteristicID: UUID?, value: Any) {
        guard let characteristicToWrite = characteristics.first(where: {$0.uniqueIdentifier == characteristicID}) else {
            print("ERROR: Characteristic not found!")
            return
        }
        // Changes the value of the characteristics and update the variable
        characteristicToWrite.writeValue(value, completionHandler: {_ in
            self.readCharacteristicValue(characteristicID: characteristicToWrite.uniqueIdentifier)
        })
    }
    
    // More speicific control with type check on write value
    func controlAccessory(accessoryIdentifier: UUID, control: Int) {
        if let accessory = accessories.first(where: { $0.uniqueIdentifier == accessoryIdentifier }) {
            // Light Services
            if let lightbulbService = accessory.services.first(where: { $0.serviceType == HMServiceTypeLightbulb }) {
                // Power control = -1
                // Brightness control = positive value of brightness
                if (control == -1) {
                    if let powerCharacteristic = lightbulbService.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypePowerState }) {
                        powerCharacteristic.writeValue(!(self.powerState ?? true), completionHandler: { error in
                            if let error = error {
                                print("Failed to change light power state: \(error)")
                            }
                        })
                    }
                } else if (control >= 0 && control <= 100) {
                    if let brightnessCharacteristic = lightbulbService.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeBrightness }) {
                        brightnessCharacteristic.writeValue(control, completionHandler: { error in
                            if let error = error {
                                print("Failed to change light brightness: \(error)")
                            }
                        })
                    }
                } else {
                    print("control value does not fall within the range")
                }
            }
            // Lock Services
            if let lockMechanismService = accessory.services.first(where: { $0.serviceType == HMServiceTypeDoor }) {
                if let lockStateCharacteristic = lockMechanismService.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeTargetLockMechanismState }) {
                    // expecting gyro control: right being lock and left being unlock
                    let lockState: HMCharacteristicValueLockMechanismState = (control > 0) ? .secured : .unsecured
                    lockStateCharacteristic.writeValue(lockState, completionHandler: { error in
                        if let error = error {
                            print("Failed to change lock state: \(error)")
                        }
                    })
                }
            }
            // Smart Blinds Services
            if let blindsServices = accessory.services.first(where: { $0.serviceType == HMServiceTypeWindowCovering }) {
                if let blindsCharacteristics = blindsServices.characteristics.first(where: { $0.characteristicType ==
                    HMCharacteristicTypeTargetPosition }) {
                    // expecting target position 0 - 100
                    blindsCharacteristics.writeValue(control, completionHandler: { error in
                        if let error = error {
                            print("Failed to change window covering position: \(error)")
                        }
                    })
                }
            }
            // Speaker Services
            if let speakerServices = accessory.services.first(where: { $0.serviceType == HMServiceTypeSpeaker }) {
                if let volumeCharacteristics = speakerServices.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeVolume }) {
                    volumeCharacteristics.writeValue(control, completionHandler: { error in
                        if let error = error {
                            print("Failed to change speaker volume: \(error)")
                        }
                    })
                }
                if let muteCharacteristics = speakerServices.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeMute }) {
                    muteCharacteristics.writeValue(!(self.mute ?? false), completionHandler: { error in
                        if let error = error {
                            print("Failed to change mute state: \(error)")
                        }
                    })
                }
            }
        }
    }
}
