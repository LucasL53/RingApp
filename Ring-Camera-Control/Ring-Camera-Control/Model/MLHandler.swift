//
//  MLHandler.swift
//  Ring-Camera-Control
//
//  Created by Yunseo Lee on 8/16/23.
//

import CoreML
import Vision
import UIKit
import AVFoundation

class MLHandler {
    private var model: MLModel
    private var visionModel: VNCoreMLModel
    private var detectionOverlay: CALayer! = nil
    
//    private lazy var module: TorchModule = {
//        if let filePath = Bundle.main.path(forResource: "model", ofType: "pt"),
//            let module = TorchModule(fileAtPath: filePath) {
//            return module
//        } else {
//            fatalError("Can't find the model file!")
//        }
//    }()

    // Initialization of the model
    init() {
        self.model = try! last(configuration: MLModelConfiguration()).model
        self.visionModel = try! VNCoreMLModel(for: model)
    }
    
    func predict(image: CGImage) -> (String, CGRect, Float) {
        var predictions: [String] = []
        var boxes: [CGRect] = []
        var confidences: [Float] = []
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        
        let request = VNCoreMLRequest(model: self.visionModel, completionHandler: { (request, error) in
            let results = request.results
            for result in results! where result is VNRecognizedObjectObservation {
                guard let objectObservation = result as? VNRecognizedObjectObservation else {
                        fatalError()
                    }
                
                // Highest confidence result
                let topLabelObservation = objectObservation.labels[0]
                let objectBounds = VNImageRectForNormalizedRect(objectObservation.boundingBox, Int(160), Int(160))
                
//                print("Found: \(topLabelObservation.identifier) at \(topLabelObservation.confidence)")
                
                predictions.append(topLabelObservation.identifier.lowercased())
                boxes.append(objectBounds)
                confidences.append(topLabelObservation.confidence)
            }
        })
        
        try! handler.perform([request])
        
        let finalPrediction = calculateCenterBox(preds: predictions, bounds: boxes, confs: confidences)
//        print(finalPrediction.1.minX, finalPrediction.1.minY, finalPrediction.1.width, finalPrediction.1.height)
        return finalPrediction
    }
    
    //MARK: - COREML
    
    func calculateCenter(boxArray: CGRect) -> (CGFloat, CGFloat) {
        //  X and Y-axis center = (Top-left/Top-right + Bottom-right/Bottom-left) / 2
        // [x, y, width, height]
        return (boxArray.midX, boxArray.midY)
    }
    
    func calculateImageCenter(originShape: [Float]) -> (CGFloat, CGFloat){
        return (CGFloat(originShape[0] / 2), CGFloat(originShape[1] / 2))
    }
    
    // Translated numpy linalg method. double check for validity
    func euclideanDistance(point1: (CGFloat, CGFloat), point2: (CGFloat, CGFloat)) -> Float {
        let deltaX = point1.0 - point2.0
        let deltaY = point1.1 - point2.1
        let distance = sqrt(pow(deltaX, 2) + pow(deltaY, 2))
        return Float(distance)
    }
    
    func overlappingArea(rect1: CGRect, rect2: CGRect) -> Float {
        let overlappingRect = rect1.intersection(rect2)
        let area = overlappingRect.width * overlappingRect.height
        return Float(area)
    }
    
    func rectArea(rect: CGRect) -> Float {
        return Float(rect.width * rect.height)
    }
    
    // Fix resultData argument Type
    func calculateCenterBox(preds: [String], bounds: [CGRect], confs: [Float]) -> (String, CGRect, Float) {
        let imageCtr = calculateImageCenter(originShape: [160, 160])
        var distance: Float = Float.infinity
//        var distance: Float = 0
        var index: Int = 0
        
        if (preds.count == 0) {
            return ("", CGRect(), 0.0)
        }

        for i in 0..<bounds.count{
            let boxCtr = calculateCenter(boxArray: bounds[i])
            let boxDistance = euclideanDistance(point1: boxCtr, point2: imageCtr)
//            var boxDistance = overlappingArea(rect1: bounds[i], rect2: CGRect(x:40, y:40, width:80, height:80))
//            let overlappedRatio = boxDistance / rectArea(rect: bounds[i])
//            boxDistance = overlappedRatio - 1
            if boxDistance < distance {
                distance = boxDistance
                index = i
            }
        }
        
        // Name of Class, Euclidean Distance
        return (preds[index], bounds[index], confs[index])
    }
    
    //MARK: - Calculations
    
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
    
    //MARK: - DINOV2
    
    // Question: What is sceneSim? Do I add e to persistence or q based on sceneSim?
    func inference(q: [[Double]], e: [[Double]]) {
        var sceneSim: Double = 0.0

        for qe in q {
            var patchSimilarities: [Double] = []
            // parallelize this
            for ee in e {
                patchSimilarities.append(cosineSimilarity(qe, ee))
            }
            sceneSim += patchSimilarities.max() ?? 0.0
        }
        sceneSim /= Double(q.count)
    }
    
//    func computeSim(q: [[[Double]]], database: [String: [String: [[Double]]]], patchLen: Int = 4) -> [String: [String: [String: Double]]] {
//        let s = 8 - (patchLen / 2)
//        let e = 8 + Int(ceil(Double(patchLen) / 2.0))
//        var sims = [String: [String: [String: Double]]]()
//
//        for (obj, vecs) in database {
//            sims[obj] = [String: [String: Double]]()
//            for (img, emb) in vecs {
//                // Object similarity using center patchLen x patchLen patch embeddings
//                let _q = q[s..<e].map { $0[s..<e].flatMap { $0 } }.mean()
//                let _emb = emb[s..<e].map { $0[s..<e].flatMap { $0 } }.mean()
//                let objSim = cosineSimilarity(_q, _emb)
//
//                // Scene similarity using image embeddings
//                let reshapedQ = q.reshaped() // Define reshaped() to reshape and permute the array
//                let reshapedEmb = emb.reshaped()
//                let sceneSim = reshapedQ.enumerated().reduce(0.0) { (acc, arg) in
//                    let (_, pe) = arg
//                    return acc + cosineSimilarity(pe, reshapedEmb).max()
//                } / Double(reshapedQ.count)
//
//                sims[obj]?[img] = ["obj": objSim, "scene": sceneSim]
//            }
//        }
//
//        return sims
//    }
    
    func inference() {
        var results: [[String: Any]] = []
        let embed_dict: [String: [[Double]]] = [:]
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
                            otherSims.append(Float(cosineSimilarity(q, embed_dict[otherObj]![j])))
                        }
                        let otherSim = otherSims.reduce(0, +) / Float(otherSims.count)
                        result[otherObj] = otherSim
                    }
                    results.append(result)
                }
        }
        
    }
    
}

// Helper extensions
extension Array where Element == Double {
    func mean() -> Double {
        return self.reduce(0, +) / Double(self.count)
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

