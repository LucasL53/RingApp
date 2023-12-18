import Foundation
import SwiftData
import SwiftUI
import HomeKit

@Model
class PhotoAndEmbedding {
    @Relationship(inverse: \AccessoryEmbedding.photoAndEmbeddings)
    var accessory: AccessoryEmbedding?
    
    @Attribute(.externalStorage) var photo: Data?
    var embedding: [Double] // Replace Double with the correct type for your embedding

    init(photo: Data, embedding: [Double]) {
        self.photo = photo
        self.embedding = embedding
    }
    
}

@Model
class AccessoryEmbedding {
    @Relationship(inverse: \HomeEmbeddings.accessoryembeddings)
    var home: HomeEmbeddings?
    
    var accessoryUUID: UUID
    var accessoryName: String
    
    @Relationship(deleteRule: .cascade)
    var photoAndEmbeddings: [PhotoAndEmbedding]

    init(accessoryUUID: UUID, accessoryName: String, photoAndEmbeddings: [PhotoAndEmbedding] = []) {
        self.accessoryUUID = accessoryUUID
        self.accessoryName = accessoryName
        self.photoAndEmbeddings = photoAndEmbeddings
    }
    
    func isComplete() -> Bool {
        return photoAndEmbeddings.count >= 15
    }
    
    func size() -> Int {
        return photoAndEmbeddings.count
    }
}

@Model
class HomeEmbeddings {
    @Attribute(.unique) var home: String
    
    @Relationship(deleteRule: .cascade)
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
