import Foundation
import HomeKit
//import Combine

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
    
    // TODO: Would using an array of Characteristics help?
    
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
    @Published var lockCurrentState: Int? // current using string to indicate Unsecured/Secured/Jammed/Unknown
    @Published var lockTargetState: Bool? // True/False for Secured/Unsecured respectively
    
    // Speaker
    @Published var mute: Bool?
    @Published var volume: Int?

    override init(){
        super.init()
        load()
    }
    
    // manager will update the @Published array of homes,
    func load() {
        if manager == nil {
            manager = .init()
            manager.delegate = self
        }
    }

    func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
        print("DEBUG: Updated Homes!")
        self.homes = self.manager.homes
    }
    
    func findAccessories(homeId: UUID) {
        guard let devices = homes.first(where: {$0.uniqueIdentifier == homeId})?.accessories else {
            print("ERROR: No Accessory not found!")
            return
        }
        accessories = devices
    }
    func findServices(accessoryId: UUID, homeId: UUID){
        guard let accessoryServices = homes.first(where: {$0.uniqueIdentifier == homeId})?.accessories.first(where: {$0.uniqueIdentifier == accessoryId})?.services else {
            print("ERROR: No Services found!")
            return
        }
        services = accessoryServices
    }
    func findCharacteristics(serviceId: UUID, accessoryId: UUID, homeId: UUID){
        guard let serviceCharacteristics = homes.first(where: {$0.uniqueIdentifier == homeId})?.accessories.first(where: {$0.uniqueIdentifier == accessoryId})?.services.first(where: {$0.uniqueIdentifier == serviceId})?.characteristics else {
            print("ERROR: No Services found!")
            return
        }
        characteristics = serviceCharacteristics
    }
    
    // READ/SET CHARACTERISTICS
    // TODO: also remodel this to set this characteristics
    func setCharacteristicValue(characteristicID: UUID?, value: Any) {
        guard let characteristicToWrite = characteristics.first(where: {$0.uniqueIdentifier == characteristicID}) else {
            print("ERROR: Characteristic not found!")
            return
        }
        characteristicToWrite.writeValue(value, completionHandler: {_ in
            self.readCharacteristicValue(characteristicID: characteristicToWrite.uniqueIdentifier)
        })
    }
    
    // Reading individual Characteristic to change
    // TODO: how would I remodel this to update a characteristic
    func readCharacteristicValue(characteristicID: UUID?){
        guard let characteristicToRead = characteristics.first(where: {$0.uniqueIdentifier == characteristicID}) else {
            print("ERROR: Characteristic not found!")
            return
        }
        readingData = true
        characteristicToRead.readValue(completionHandler: {_ in
            if characteristicToRead.localizedDescription == "Power State" {
                self.powerState = characteristicToRead.value as? Bool
            }
            if characteristicToRead.localizedDescription == "Hue" {
                self.hueValue = characteristicToRead.value as? Int
            }
            if characteristicToRead.localizedDescription == "Brightness" {
                self.brightnessValue = characteristicToRead.value as? Int
            }
            self.readingData = false
        })
    }
    
    // Reading new initial values of Charactersistics to add
    // TODO: maybe a dictionary with key(characteristics.localizedDescription), value(characteristics.value)
    func readCharacteristicValues(serviceId: UUID){
        guard let characteristicsToRead = services.first(where: {$0.uniqueIdentifier == serviceId})?.characteristics else {
            print("ERROR: Characteristic not found!")
            return
        }
        readingData = true
        for characteristic in characteristicsToRead {
            characteristic.readValue(completionHandler: {_ in
                print("DEBUG: reading characteristic value: \(characteristic.localizedDescription)")
                if characteristic.localizedDescription == "Power State" {
                    self.powerState = characteristic.value as? Bool
                }
                if characteristic.localizedDescription == "Hue" {
                    self.hueValue = characteristic.value as? Int
                }
                if characteristic.localizedDescription == "Brightness" {
                    self.brightnessValue = characteristic.value as? Int
                }
                if characteristic.localizedDescription == "Current Position" {
                    self.currentPosition = characteristic.value as? Int
                }
                if characteristic.localizedDescription == "Target Position" {
                    self.targetPosition = characteristic.value as? Int
                }
                if characteristic.localizedDescription == "Position State" {
                    self.positionState = characteristic.value as? Int
                }
                if characteristic.localizedDescription == "Obstruction Detected" {
                    self.obstructionDetected = characteristic.value as? Bool
                }
                if characteristic.localizedDescription == "Lock Current State" {
                    self.lockCurrentState = characteristic.value as? Int
                }
                if characteristic.localizedDescription == "Lock Target State" {
                    self.lockTargetState = characteristic.value as? Bool
                }
                self.readingData = false
            })
        }
    }
}
