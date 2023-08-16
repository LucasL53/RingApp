//
//  MLHandler.swift
//  Ring-Camera-Control
//
//  Created by Yunseo Lee on 8/16/23.
//

import CoreML

class MLHandler {
    private var model: TestModel! // Implicitly unwrapped optional
    
    // Labels mapping from class indices to names
    private let labels = ["Light-bulb", "Window-blind", "smart lock", "speaker", "tv"]

    // Initialization of the model
    init() {
        do {
            let configuration = MLModelConfiguration()
            self.model = try TestModel(configuration: configuration)
        } catch {
            print("Error initializing model: \(error)")
        }
    }
    
    // Function to predict from an image
    func predict(image: CVPixelBuffer) {
        do {
            let prediction = try model.prediction(image: image)
            
            // return a MultiArray(Float32)
            let outputArray = prediction.var_379
            
            // Find the index of the class with the highest probability
            let maxIndex = outputArray.argmax()
            let maxLabel = labels[maxIndex]

            // Print the prediction
            print("Prediction: \(maxLabel)")

            // Optionally, print all probabilities with corresponding labels
//            for i in 0..<labels.count {
//                let probability = outputArray[i].floatValue
//                print("\(labels[i]): \(probability)")
//            }
        } catch {
            print("Error making prediction: \(error)")
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


