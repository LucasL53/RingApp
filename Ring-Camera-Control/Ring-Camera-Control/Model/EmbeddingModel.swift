import Foundation
import SwiftData
import SwiftUI
import HomeKit

@Model
class PhotoAndEmbedding {
    @Attribute(.externalStorage) var photo: Data? // Assuming photos are stored as UIImage
    var embedding: [Double] // Replace Double with the correct type for your embedding

    init(photo: Data, embedding: [Double]) {
        self.photo = photo
        self.embedding = embedding
    }
}

@Model
class AccessoryEmbedding {
    var accessoryUUID: UUID
    var accessoryName: String
    var photoAndEmbeddings: [PhotoAndEmbedding]

    init(accessoryUUID: UUID, accessoryName: String, photoAndEmbeddings: [PhotoAndEmbedding] = []) {
        self.accessoryUUID = accessoryUUID
        self.accessoryName = accessoryName
        self.photoAndEmbeddings = photoAndEmbeddings
    }
}

@Model
class HomeEmbeddings {
    @Attribute(.unique) var home: String
    var accessoryembeddings: [AccessoryEmbedding]
    
    init(home: String, accessoryembeddings: [AccessoryEmbedding]) {
        self.home = home
        self.accessoryembeddings = accessoryembeddings
    }
    
    func isPopulated() -> Bool {
        for accessoryembedding in accessoryembeddings {
            if accessoryembedding.photoAndEmbeddings.isEmpty {
                return false
            }
        }
        return true
    }
    
    func hasAccessory(accessoryName: String) -> Bool {
        for accessoryembedding in accessoryembeddings {
            if accessoryembedding.accessoryName == accessoryName {
                return true
            }
        }
        return false
    }
}
