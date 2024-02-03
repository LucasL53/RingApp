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
    
    struct Detection {
        let box:CGRect
        let confidence:Float
        let label:String?
        let color:UIColor
    }

    func drawDetectionsOnImage(_ detections: [Detection], _ image: UIImage) -> UIImage? {
        let imageSize = image.size
        let scale: CGFloat = 0.0
        UIGraphicsBeginImageContextWithOptions(imageSize, false, scale)

        image.draw(at: CGPoint.zero)
        let ctx = UIGraphicsGetCurrentContext()
        var rects:[CGRect] = []
        for detection in detections {
            rects.append(detection.box)
            if let labelText = detection.label {
            let text = "\(labelText) : \(round(detection.confidence*100))"
                let textRect  = CGRect(x: detection.box.minX + imageSize.width * 0.01, y: detection.box.minY + imageSize.width * 0.01, width: detection.box.width, height: detection.box.height)
                        
            let textStyle = NSMutableParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
                        
            let textFontAttributes = [
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: textRect.width * 0.1, weight: .bold),
                NSAttributedString.Key.foregroundColor: detection.color,
                NSAttributedString.Key.paragraphStyle: textStyle
            ]
                        
            text.draw(in: textRect, withAttributes: textFontAttributes)
            ctx?.addRect(detection.box)
            ctx?.setStrokeColor(detection.color.cgColor)
            ctx?.setLineWidth(1.0)
            ctx?.strokePath()
            }
        }

        guard let drawnImage = UIGraphicsGetImageFromCurrentImageContext() else {
            fatalError()
        }

        UIGraphicsEndImageContext()
        return drawnImage
    }
    
    func predict(image: CGImage) -> UIImage {
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
                
                print("Found: \(topLabelObservation.identifier)")
                
                predictions.append(topLabelObservation.identifier.lowercased())
                boxes.append(objectBounds)
                confidences.append(topLabelObservation.confidence)
                
                let shapeLayer = self.createRoundedRectLayerWithBounds(objectBounds)
        
                let textLayer = self.createTextSubLayerInBounds(objectBounds,
                            identifier: topLabelObservation.identifier.lowercased(),
                            confidence: topLabelObservation.confidence)
                
                shapeLayer.addSublayer(textLayer)
            }
        })
        
        try! handler.perform([request])
        
        let finalPrediction = calculateCenterBox(preds: predictions, bounds: boxes, confs: confidences)
        
        return drawDetectionsOnImage([Detection(box: finalPrediction.1, confidence: finalPrediction.2, label: finalPrediction.0, color: .green)], UIImage(cgImage: image))!
    }
    
    func createTextSubLayerInBounds(_ bounds: CGRect, identifier: String, confidence: VNConfidence) -> CATextLayer {
        let textLayer = CATextLayer()
        textLayer.name = "Object Label"
        let formattedString = NSMutableAttributedString(string: String(format: "\(identifier)\n: %.3f", confidence*100) + "%")
        let largeFont = UIFont(name: "Helvetica", size: 15.0)!
        formattedString.addAttributes([NSAttributedString.Key.font: largeFont], range: NSRange(location: 0, length: identifier.count))
        textLayer.string = formattedString
        textLayer.bounds = CGRect(x: 0, y: 0, width: bounds.size.height - 10, height: bounds.size.width - 10)
        textLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        textLayer.shadowOpacity = 0.7
        textLayer.shadowOffset = CGSize(width: 2, height: 2)
        textLayer.foregroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [0.0, 0.0, 0.0, 1.0])
        textLayer.contentsScale = 2.0 // retina rendering
        // rotate the layer into screen orientation and scale and mirror
        textLayer.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(.pi / 2.0)).scaledBy(x: 1.0, y: -1.0))
        return textLayer
    }
    
    func createRoundedRectLayerWithBounds(_ bounds: CGRect) -> CALayer {
        let shapeLayer = CALayer()
        shapeLayer.bounds = bounds
        shapeLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        shapeLayer.name = "Found Object"
        shapeLayer.backgroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [1.0, 1.0, 0.2, 0.4])
        shapeLayer.cornerRadius = 7
        return shapeLayer
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
        let squaredDifference = deltaX * deltaX + deltaY * deltaY
        return Float(sqrt(squaredDifference))
    }
    
    // Fix resultData argument Type
    func calculateCenterBox(preds: [String], bounds: [CGRect], confs: [Float]) -> (String, CGRect, Float) {
        let imageCtr = calculateImageCenter(originShape: [160, 160])
        var distance: Float = Float.infinity
        var index: String = ""
        var bound: CGRect = CGRect()
        var conf: Float = Float.zero

        for i in 0..<bounds.count{
            let boxCtr = calculateCenter(boxArray: bounds[i])
            let boxDistance = euclideanDistance(point1: boxCtr, point2: imageCtr)
            if distance > boxDistance {
                distance = boxDistance
                index = preds[i]
                bound = bounds[i]
                conf = confs[i]
            }
        }
        
        // Name of Class, Euclidean Distance
        return (index, bound, conf)
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

