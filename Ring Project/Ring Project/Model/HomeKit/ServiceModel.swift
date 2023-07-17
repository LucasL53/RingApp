import HomeKit

extension HMService {
    enum ServiceType {
        case lightBulb, swtch, doorBell, door, window, security, windowCovering, unknown
    }
    
    var homeServiceType: ServiceType {
        switch serviceType {
        case HMServiceTypeLightbulb: return .lightBulb
        case HMServiceTypeSwitch: return .swtch
        case HMServiceTypeDoorbell: return .doorBell
        case HMServiceTypeDoor: return .door
        case HMServiceTypeWindow: return .window
        case HMServiceTypeSecuritySystem: return .security
        case HMServiceTypeWindowCovering: return .windowCovering
        default: return .unknown
        }
    }
    
    var primaryControlCharacteristicType: String? {
        switch homeServiceType {
        case .lightBulb: return HMCharacteristicTypePowerState
        case .swtch: return HMCharacteristicTypeOutputState
        case .doorBell: return HMCharacteristicTypeTargetDoorState
        case .door: return HMCharacteristicTypeTargetDoorState
        case .window: return HMCharacteristicTypeCurrentPosition
        case .security: return HMCharacteristicTypeTargetSecuritySystemState
        case .windowCovering: return HMCharacteristicTypeSwingMode
        case .unknown: return nil
        }
    }

    var primaryControlCharacteristic: HMCharacteristic? {
        return characteristics.first { $0.characteristicType == primaryControlCharacteristicType }
    }

    var primaryDisplayCharacteristicType: String? {
        switch homeServiceType {
        case .lightBulb: return HMCharacteristicTypePowerState
        case .swtch: return HMCharacteristicTypeOutputState
        case .doorBell: return HMCharacteristicTypeCurrentDoorState
        case .door: return HMCharacteristicTypeCurrentDoorState
        case .window: return HMCharacteristicTypeCurrentPosition
        case .security: return HMCharacteristicTypeCurrentSecuritySystemState
        case .windowCovering: return HMCharacteristicTypeSwingMode
        case .unknown: return nil
        }
    }
    
    var primaryDisplayCharacteristic: HMCharacteristic? {
        return characteristics.first { $0.characteristicType == primaryDisplayCharacteristicType }
    }
    
    enum KilgoCharacteristicTypes: String {
        case fadeRate = "7E536242-341C-4862-BE90-272CE15BD633"
    }

    var displayableCharacteristics: [HMCharacteristic] {
        let characteristicTypes = [HMCharacteristicTypePowerState,
                                   HMCharacteristicTypeBrightness,
                                   HMCharacteristicTypeHue,
                                   HMCharacteristicTypeSaturation,
                                   HMCharacteristicTypeTargetDoorState,
                                   HMCharacteristicTypeCurrentDoorState,
                                   HMCharacteristicTypeObstructionDetected,
                                   HMCharacteristicTypeTargetLockMechanismState,
                                   HMCharacteristicTypeCurrentLockMechanismState,
                                   HMCharacteristicTypeCurrentPosition,                                   KilgoCharacteristicTypes.fadeRate.rawValue]
        
        return characteristics.filter { characteristicTypes.contains($0.characteristicType) }
    }

    var icon: UIImage? {
        let (_, icon) = stateAndIcon
        return icon
    }
    
    var state: String {
        let (state, _) = stateAndIcon
        return state
    }
    
    private var stateAndIcon: (String, UIImage?) {
        switch homeServiceType {
        case .lightBulb:
            return ("Unknown", #imageLiteral(resourceName: "bulb-on"))
        case .swtch:
            return ("Unknown", #imageLiteral(resourceName: "lightswitch.off"))
        case .doorBell:
            return ("Unknown", #imageLiteral(resourceName: "video.doorbell"))
        case .door:
            return ("Unknown", #imageLiteral(resourceName: "video.doorbell"))
        case .window:
            return ("Unknown", #imageLiteral(resourceName: "window.shade.closed"))
        case .security:
            return ("Unknown", #imageLiteral(resourceName: "lock.shield"))
        case .windowCovering:
            return ("Unknown", #imageLiteral(resourceName: "window.shade.closed"))
        case .unknown:
            return ("Unknown", nil)
        }
    }
}
