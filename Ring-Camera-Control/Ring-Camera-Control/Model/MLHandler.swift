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
}

extension MLMultiArray {
    func argmax() -> Int {
        let valuesPointer = self.dataPointer.bindMemory(to: Float.self, capacity: self.count)
        let valuesBuffer = UnsafeBufferPointer(start: valuesPointer, count: self.count)
        let valuesArray = Array(valuesBuffer)
        return valuesArray.firstIndex(of: valuesArray.max()!) ?? 0
    }
}

