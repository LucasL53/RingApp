//
//  MLHandler.swift
//  Ring-Camera-Control
//
//  Created by Yunseo Lee on 8/16/23.
//

import CoreML

class MLHandler {
    private var model: best160x128! // Implicitly unwrapped optional

    
    // Labels mapping from class indices to names
    private let labels = ["lights", "blinds", "lock", "speaker", "tv"]
    

    // Initialization of the model
    init() {
        do {
            let configuration = MLModelConfiguration()
            self.model = try best160x128(configuration: configuration)
        } catch {
            print("Error initializing model: \(error)")
        }
    }
    
    // Function to predict from an image
    func predict(image: CVPixelBuffer) -> Int {
        do {
            let prediction = try model.prediction(image: image)
            
            // return a MultiArray(Float32)
            let outputArray = prediction.var_379
            
            // Find the index of the class with the highest probability
            let maxIndex = outputArray.argmax()
            let maxLabel = labels[maxIndex]

            
            // Optionally, print all probabilities with corresponding labels
            for i in 0..<labels.count {
                let probability = outputArray[i].floatValue
                print("\(labels[i]): \(probability)")
            }
            // Print the prediction
            print("Prediction: \(maxLabel)\n")
            
            return maxIndex
//            return identifiers[maxIndex]
        } catch {
            print("Error making prediction: \(error)")
        }
        
        return -1
    }
    
    func calculateCenter(boxArray: [Double]) -> [Double] {
        let centerX = (boxArray[2] + boxArray[0]) / 2
        let centerY = (boxArray[3] + boxArray[1]) / 2
        return [centerX, centerY]
    }
    
    func calculateImageCenter(originShape: [Double]) -> (Double, Double) {
        return (originShape[0] / 2, originShape[1] / 2)
    }
    
    // Translated numpy linalg method. double check for validity
    func euclideanDistance(point1: [Double], point2: [Double]) -> Double? {
        guard point1.count == point2.count else { return nil }
        // Calculate the squared differences between corresponding coordinates of the two points
        let squaredDifference = zip(point1, point2).map { ($0 - $1) * ($0 - $1) }
        let sumOfSquaredDifference = squaredDifference.reduce(0, +)
        return sqrt(sumOfSquaredDifference)
    }
    
    // Fix resultData argument Type
    func calculateCenterBox(resultData: [[Double]]) -> (Int, Double) {
        let imageCtr = calculateImageCenter(originShape: []) // get resultData origShape?
        var distance: Double = Double.infinity
        var index: Int = -1
        
//          Need to know coreml output.
//        for i in range(0, resultData.boxes.shape[0]):
//                boxCtr = calculateCenter(resultData.boxes.xyxy[i])
//                boxDistance = euclideanDsitan(boxCtr, imageCtr)
//                if distance > boxDistance:
//                    distance = boxDistance
//                    lowestIndex = i
        
        return (index, distance)
    }
    
    // Cosine Similarity Calculation
    func dotProduct(_ vectorA: [Double], _ vectorB: [Double]) -> Double {
        precondition(vectorA.count == vectorB.count, "Vectors must have the same length")
        return zip(vectorA, vectorB).map(*).reduce(0, +)
    }

    func magnitude(_ vector: [Double]) -> Double {
        return sqrt(vector.map { $0 * $0 }.reduce(0, +))
    }

    func cosineSimilarity(_ vectorA: [Double], _ vectorB: [Double]) -> Double {
        precondition(vectorA.count == vectorB.count, "Vectors must have the same length")
        let dotProductValue = dotProduct(vectorA, vectorB)
        return dotProductValue / (magnitude(vectorA) * magnitude(vectorB))
    }
    
    func inference() {
        var results: [[String: Any]] = []
        let embed_dict: [String: [[Any]]] = [:]
        let embed_dict_keys = [String](embed_dict.keys)
        for obj in embed_dict_keys {
            print("\nEvaluating \(obj)...")
            for i in 0..<embed_dict[obj]!.count {
                    var result: [String: Any] = ["Query": obj, "Index": "\(i)"]
                    let q = embed_dict[obj]![i]
                    
                    // Same instance similarity
                    var sims: [Float] = []
                    for j in 0..<embed_dict[obj]!.count {
                        if j == i { continue }
//                        sims.append(cosineSimilarity(q, embedDict[obj]![j]))
                    }
                    let sameSim = sims.reduce(0, +) / Float(sims.count)
                    result[obj] = sameSim
                    
                    // Other similarity
                    for otherObj in embed_dict_keys {
                        if otherObj == obj { continue }
                        var otherSims: [Float] = []
                        for j in 0..<embed_dict[otherObj]!.count {
//                            otherSims.append(cosineSimilarity(q, embedDict[otherObj]![j]))
                        }
                        let otherSim = otherSims.reduce(0, +) / Float(otherSims.count)
                        result[otherObj] = otherSim
                    }
                    results.append(result)
                }
        }
        
    }
    
}

extension MLMultiArray {
    func argmax() -> Int {
        let valuesPointer = self.dataPointer.bindMemory(to: Float.self, capacity: self.count)
        let valuesBuffer = UnsafeBufferPointer(start: valuesPointer, count: self.count)
        let valuesArray = Array(valuesBuffer)
        return valuesArray.firstIndex(of: valuesArray.max()!) ?? 0
    }
}

