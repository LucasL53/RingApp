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
import onnxruntime_objc

class MLHandler {
    private var model: MLModel
    private var visionModel: VNCoreMLModel
    private var detectionOverlay: CALayer! = nil
    
    // DINOV2 model
    let ortSession: ORTSession
    let ortEnv: ORTEnv
    
//    private lazy var module: TorchModule = {
//        if let filePath = Bundle.main.path(forResource: "model", ofType: "pt"),
//            let module = TorchModule(fileAtPath: filePath) {
//            return module
//        } else {
//            fatalError("Can't find the model file!")
//        }
//    }()

    enum ModelError: Error {
        case Error(_ message: String)
    }
    
    // Initialization of the model
    init() throws {
        let config = MLModelConfiguration()
        config.setValue(1, forKey: "experimentalMLE5EngineUsage")
        self.model = try! best_75(configuration: config).model
        self.visionModel = try! VNCoreMLModel(for: model)

        // Loading DINOV2
        let name = "ring_dinov2_nearestinterp_nocrop"
        ortEnv = try! ORTEnv(loggingLevel: ORTLoggingLevel.warning)
        guard let modelPath = Bundle.main.path(forResource: name, ofType: "ort") else {
            throw ModelError.Error("Failed to find model file:\(name).ort")
        }
        ortSession = try! ORTSession(env: ortEnv, modelPath: modelPath, sessionOptions: nil)
    }
    
    
    // MARK: - Dinov2
    
    // Generate an embedding from Dino
    func DinoEmbedding(img_buf: [UInt8]) -> [[[Float]]]? {
        let flatTensor =  Array(repeating: img_buf, count: 3).flatMap { $0 }
        let shape: [NSNumber] = [NSNumber(value: 3), NSNumber(value: 162), NSNumber(value: 119)]
        let data_obj = flatTensor.withUnsafeBufferPointer { Data(buffer: $0) }
        
        do {
            let ortInput = try ORTValue(
                        tensorData: NSMutableData(data: data_obj),
                        elementType: ORTTensorElementDataType.float,
                        shape: shape)

            let output = try ortSession.run(withInputs: ["input_img": ortInput],
                                                     outputNames: ["x_norm_patchtokens"],
                                                     runOptions: nil)
            
            guard let ORTout = output["x_norm_patchtokens"] else {
                print("output was null in Dino run")
                return nil
            }

            return ORTToTensor(ortValue: ORTout)
        } catch {
            print("error computing Dino feats: \(error)")
            return nil
        }
    }
    
    // Converts ORTValue to a 3D array of Floats
    func ORTToTensor(ortValue: ORTValue) -> [[[Float]]]? {
        guard let tensorData = try? ortValue.tensorData() as Data else {
            print("Failed to get tensor data from ORTValue")
            return nil
        }
        
        guard let shapeNumbers = try? ortValue.tensorTypeAndShapeInfo().shape else {
          print("ORTValue does not contain a valid shape")
          return nil
        }
        let shape = shapeNumbers.map { Int(truncating: $0) }
        guard shape.count == 3 else {
          print("ORTValue does not contain a 3D tensor")
          return nil
        }
        let totalElements = shape.reduce(1, *)
                guard tensorData.count == totalElements * MemoryLayout<Float>.size else {
            print("Mismatch between expected tensor size and actual data size")
            return nil
        }
        
        let floatValues: [Float] = tensorData.withUnsafeBytes {
            Array(UnsafeBufferPointer(start: $0.baseAddress!.assumingMemoryBound(to: Float.self), count: totalElements))
        }
        
        var threeDArray: [[[Float]]] = Array(repeating: Array(repeating: Array(repeating: 0, count: shape[2]), count: shape[1]), count: shape[0])
        for i in 0..<shape[0] {
            for j in 0..<shape[1] {
                for k in 0..<shape[2] {
                    threeDArray[i][j][k] = floatValues[i * shape[1] * shape[2] + j * shape[2] + k]
                }
            }
        }
        
        return threeDArray
    }
    
    func predict(image: CGImage) -> [(String, CGRect, Float)] {
        var predictions: [String] = []
        var boxes: [CGRect] = []
        var confidences: [Float] = []
        var preds: [(String, CGRect, Float)] = []
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
                
                preds.append((topLabelObservation.identifier.lowercased(), objectBounds, topLabelObservation.confidence))
    
            }
        })
        
        try! handler.perform([request])
        
        let iouThreshold: Float = 0.5
        
//        print(predictions)
        
        var filteredPredictions: [(String, CGRect, Float)] = []

        for pred in preds {
            var shouldAdd = true
            for filteredPred in filteredPredictions {
                if calculateIOU(rectA: pred.1, rectB: filteredPred.1) > iouThreshold {
                    // If the current prediction overlaps significantly with an existing one,
                    // only add it if it has a higher confidence.
                    if pred.2 <= filteredPred.2 {
                        shouldAdd = false
                        break
                    }
                }
            }
            if shouldAdd {
                filteredPredictions = filteredPredictions.filter { calculateIOU(rectA: pred.1, rectB: $0.1) <= iouThreshold }
                filteredPredictions.append(pred)
            }
        }
//        
//        for p in filteredPredictions {
//            print("Filtered preds: ", p.0)
//        }
        
        var finalPrediction = [calculateCenterBox(preds: predictions, bounds: boxes, confs: confidences)]
        
        for p in preds {
            if !finalPrediction.contains(where: {$0 == p}) {
                finalPrediction.append(p)
            }
        }
        return finalPrediction
//        if filteredPredictions.isEmpty {
//            filteredPredictions.append(("", CGRect(), 0.0))
//        }
//        
//        return filteredPredictions
    }
    
    //MARK: - Non Max Suppression
    func calculateIOU(rectA: CGRect, rectB: CGRect) -> Float {
        let intersection = rectA.intersection(rectB)
        let interArea = intersection.width * intersection.height
        let unionArea = rectA.width * rectA.height + rectB.width * rectB.height - interArea
//        print(Float(interArea / unionArea))
        return Float(interArea / unionArea)
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

