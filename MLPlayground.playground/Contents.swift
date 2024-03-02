import UIKit
import CoreML
import AVFoundation
import Foundation
import Vision
import VideoToolbox

extension UIImage {
    public convenience init?(pixelBuffer: CVPixelBuffer) {
        var cgImage: CGImage?
        VTCreateCGImageFromCVPixelBuffer(pixelBuffer, options: nil, imageOut: &cgImage)

        guard let cgImage = cgImage else {
            return nil
        }

        self.init(cgImage: cgImage)
    }
}

public extension UIImage {
    func normalized() -> [Float32]? {
         guard let cgImage = self.cgImage else {
             return nil
         }
         let w = cgImage.width
         let h = cgImage.height
         let bytesPerPixel = 4
         let bytesPerRow = bytesPerPixel * w
         let bitsPerComponent = 8
         var rawBytes: [UInt8] = [UInt8](repeating: 0, count: w * h * 4)
         rawBytes.withUnsafeMutableBytes { ptr in
             if let cgImage = self.cgImage,
                 let context = CGContext(data: ptr.baseAddress,
                                         width: w,
                                         height: h,
                                         bitsPerComponent: bitsPerComponent,
                                         bytesPerRow: bytesPerRow,
                                         space: CGColorSpaceCreateDeviceRGB(),
                                         bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) {
                 let rect = CGRect(x: 0, y: 0, width: w, height: h)
                 context.draw(cgImage, in: rect)
             }
         }
         var normalizedBuffer: [Float32] = [Float32](repeating: 0, count: w * h * 3)
         // normalize the pixel buffer
         // see https://pytorch.org/hub/pytorch_vision_resnet/ for more detail
         for i in 0 ..< w * h {
             normalizedBuffer[i] = (Float32(rawBytes[i * 4 + 0]) / 255.0 - 0.485) / 0.229 // R
             normalizedBuffer[w * h + i] = (Float32(rawBytes[i * 4 + 1]) / 255.0 - 0.456) / 0.224 // G
             normalizedBuffer[w * h * 2 + i] = (Float32(rawBytes[i * 4 + 2]) / 255.0 - 0.406) / 0.225 // B
         }
         return normalizedBuffer
     }
    
    func convertToBuffer() -> CVPixelBuffer? {
        
        let attributes = [
            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue
        ] as CFDictionary
        
        var pixelBuffer: CVPixelBuffer?
        
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault, Int(self.size.width),
            Int(self.size.height),
            kCVPixelFormatType_32ARGB,
            attributes,
            &pixelBuffer)
        
        guard (status == kCVReturnSuccess) else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        
        let context = CGContext(
            data: pixelData,
            width: Int(self.size.width),
            height: Int(self.size.height),
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!),
            space: rgbColorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        
        context?.translateBy(x: 0, y: self.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)
        
        UIGraphicsPushContext(context!)
        self.draw(in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
        UIGraphicsPopContext()
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        
        return pixelBuffer
    }
}

func createGrayScalePixelBuffer(image: UIImage, width: Int, height: Int) -> CVPixelBuffer? {
    let ciImage = CIImage(image: image)
    let filter = CIFilter(name: "CIColorControls")!
    filter.setValue(ciImage, forKey: kCIInputImageKey)
    filter.setValue(0, forKey: kCIInputSaturationKey) // Set saturation to 0 to get grayscale

    guard let outputImage = filter.outputImage else { return nil }

    let context = CIContext()
    let pixelBufferOptions: [String: Any] = [kCVPixelBufferCGImageCompatibilityKey as String: true,
                                             kCVPixelBufferCGBitmapContextCompatibilityKey as String: true]

    var pixelBuffer: CVPixelBuffer? = nil
    let status = CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32ARGB, pixelBufferOptions as CFDictionary, &pixelBuffer)
    guard status == kCVReturnSuccess, let finalPixelBuffer = pixelBuffer else {
        return nil
    }

    let rect = CGRect(x: 0, y: 0, width: width, height: height)
//        context.render(outputImage, to: finalPixelBuffer, bounds: rect, colorSpace: CGColorSpaceCreateDeviceGray())
    context.render(outputImage, to: finalPixelBuffer, bounds: rect, colorSpace: CGColorSpaceCreateDeviceRGB())
    return finalPixelBuffer
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

func centerImageOnBlackSquare(image: UIImage, squareSize: CGSize) -> UIImage? {
    // Create a black square image
    UIGraphicsBeginImageContextWithOptions(squareSize, false, 0.0)
    UIColor.black.setFill()
    UIRectFill(CGRect(origin: .zero, size: squareSize))
    let blackSquareImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    // Calculate the position to center the original image
    let xOffset = (squareSize.width - image.size.width) / 2.0
    let yOffset = (squareSize.height - image.size.height) / 2.0

    // Draw the original image on top of the black square
    UIGraphicsBeginImageContextWithOptions(squareSize, false, 0.0)
    blackSquareImage?.draw(at: .zero)
    image.draw(at: CGPoint(x: xOffset, y: yOffset))
    let centeredImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    return centeredImage
}

func resize(pixelBuffer: CVPixelBuffer, width: Int, height: Int) -> CVPixelBuffer? {
    var maybePixelBuffer: CVPixelBuffer?
    CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32ARGB, nil, &maybePixelBuffer)
    guard let resizedPixelBuffer = maybePixelBuffer else { return nil }

    CVPixelBufferLockBaseAddress(resizedPixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
    let resizedData = CVPixelBufferGetBaseAddress(resizedPixelBuffer)

    guard let context = CGContext(
        data: resizedData,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: CVPixelBufferGetBytesPerRow(resizedPixelBuffer),
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
    ) else { return nil }

    let rect = CGRect(x: 0, y: 0, width: width, height: height)
    context.clear(rect)

    let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
    let ciContext = CIContext(options: nil)
    guard let cgImage = ciContext.createCGImage(ciImage, from: rect) else { return nil }

    context.draw(cgImage, in: rect)

    CVPixelBufferUnlockBaseAddress(resizedPixelBuffer, CVPixelBufferLockFlags(rawValue: 0))

    return resizedPixelBuffer
}

// Resize UIImage to target size
func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage? {
    let size = image.size
    
    let widthRatio  = targetSize.width  / size.width
    let heightRatio = targetSize.height / size.height
    
    // Figure out what our orientation is, and use that to form the rectangle
    var newSize: CGSize
    if(widthRatio > heightRatio) {
        newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
    } else {
        newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
    }
    
    // This is the rect that we've calculated out and this is what is actually used below
    let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
    
    // Actually do the resizing to the rect using the ImageContext stuff
    UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
    image.draw(in: rect)
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return newImage
}

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
func calculateCenterBox(preds: [String], bounds: [CGRect]) -> (String, CGRect) {
    let imageCtr = calculateImageCenter(originShape: [160, 160])
    var distance: Float = Float.infinity
    var index: String = ""
    var bound: CGRect = CGRect()

    for i in 0..<bounds.count{
        let boxCtr = calculateCenter(boxArray: bounds[i])
        let boxDistance = euclideanDistance(point1: boxCtr, point2: imageCtr)
        if distance > boxDistance {
            distance = boxDistance
            index = preds[i]
            bound = bounds[i]
        }
    }
    
    // Name of Class, Euclidean Distance
    return (index, bound)
}

func boundingBoxToImage(drawText text: String, inImage image: UIImage, inRect rect: CGRect) -> UIImage {
    // font attributes
    let textColor = UIColor.systemPink
    let textFont = UIFont(name: "Helvetica Bold", size: 10)!
    
    // Setup image context using the given image
    let scale = UIScreen.main.scale
    UIGraphicsBeginImageContextWithOptions(image.size, false, scale)
    
    // Setup font attributes
    let textFontAttributes = [
            NSAttributedString.Key.font: textFont,
            NSAttributedString.Key.foregroundColor: textColor,
            ] as [NSAttributedString.Key : Any]
        image.draw(in: CGRect(origin: CGPoint.zero, size: image.size))

    // Create a point within the space to write text
    text.draw(in: rect, withAttributes: textFontAttributes)
    
    // Create a point within the space to draw rectangle
//        image.draw(in: rect)
    
    // Create a new image out of the images we made graphical addition
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    return newImage!
}

// MARK: - Setting up ML Model

var urlOfModelInThisBundle: URL { let resPath = Bundle.main.url(forResource: "last", withExtension: "mlmodelc")!; return try! MLModel.compileModel(at: resPath) }
var image = UIImage(named: "test_set/tv/IMG_3313.JPG")
image = centerImageOnBlackSquare(image: image!, squareSize: CGSize(width: 224, height: 224))

//let resizedImgTest = resizeImage(image: image!, targetSize: CGSize(width: 160, height: 160))

let modelURL = Bundle.main.url(forResource: "last", withExtension: "mlmodelc")!
let model = try! VNCoreMLModel(for: MLModel(contentsOf: modelURL))
var preds: [String] = []
var bounds: [CGRect] = []

let handler = VNImageRequestHandler(cgImage: image!.cgImage!, options: [:])
let request = VNCoreMLRequest(model: model, completionHandler: { (request, error) in
//    guard let results = request.results as? [VNClassificationObservation] else {
//        fatalError()
//    }
    let results = request.results
    for result in results! where result is VNRecognizedObjectObservation {
        guard let objectObservation = result as? VNRecognizedObjectObservation else {
                fatalError()
            }
        let obj = objectObservation.labels[0].identifier
        print(obj, objectObservation.labels[0].confidence)
        let objectBounds = VNImageRectForNormalizedRect(objectObservation.boundingBox, Int(160), Int(160))
        type(of: objectBounds)
        bounds.append(objectBounds)
        preds.append(obj)
    }
    let classification = results
    print("[predict result]")
})
try! handler.perform([request])

let calc = calculateCenterBox(preds: preds, bounds: bounds)
let det = Detection(box: calc.1, confidence: 0.0, label: calc.0, color: .green)
let dets = [det]

resizeImage(image: drawDetectionsOnImage(dets, image!)!, targetSize: CGSize(width: 320, height: 320))

let noBorderBuffer = (image?.convertToBuffer())!
let noBorderImage = UIImage(pixelBuffer: noBorderBuffer)
image = centerImageOnBlackSquare(image: image!, squareSize: CGSize(width: 160, height: 160))
//let newimage = centerImageOnBlackSquare(image: image!, squareSize: CGSize(width: 160, height: 160))
let buffer = (image?.convertToBuffer())!
let myBuffer = (image?.convertToBuffer())!
let maruchiBuffer = createGrayScalePixelBuffer(image: image!, width: 160, height: 160)
let address = CVPixelBufferGetDataSize(buffer)
let resized_buffer = resize(pixelBuffer: (image?.convertToBuffer())!, width: 160, height: 160)
let resized_buffer_size = CVPixelBufferGetDataSize(resized_buffer!)
let borderlessImage = noBorderImage
let transformedImage = UIImage(pixelBuffer: myBuffer)
let maruchiImage = UIImage(pixelBuffer: maruchiBuffer!)
//let colors = transformedImage!.colors
let result = try! last().prediction(image: buffer, iouThreshold: 0.2, confidenceThreshold: 0.25)
// MARK: - Handling result
//
let classConfidence = result.confidence
let classCoordinate = result.coordinates
let labels = ["Door", "Door handle", "Window", "Blind", "Lights", "Smart Lock", "Speaker", "TV"]
// Name : [x, y, width, height]
var classMap: [String: [Float]] = [:]
var fakeArr: [String] = []
var fakePos: [[Float]] = []
var maxIndex: Int = -1
var maxValue: Float = -1.0
for i in 0..<classConfidence.shape[0].intValue {
    maxValue = -1.0
    maxIndex = -1
    for j in 0..<classConfidence.shape[1].intValue {
        let index = [NSNumber(value: i), NSNumber(value: j)]
        let value = classConfidence[index].floatValue
//         print("Value at [\(i), \(j),]: \(value)")
        if maxValue < value {
            maxValue = value
            maxIndex = j
        }
    }
    fakeArr.append(labels[maxIndex])
    
//    print("Predicted \(labels[maxIndex]) at confidence \(maxValue)")
    classMap[labels[maxIndex]] = [Float.zero]
    var objectArray = [Float]()
    for k in 0..<classCoordinate.shape[1].intValue {
        let index = [NSNumber(value: i), NSNumber(value: k)]
        let value = classCoordinate[index].floatValue
        objectArray.append(value)
    }
    fakePos.append(objectArray)
    classMap[labels[maxIndex]] = objectArray
    print(i)
}
//print("map contains: \(classMap.keys), \(classMap.values)")
var newImage = transformedImage!
for (key, value) in classMap {
//    print("x: \(value[0] * Float(newImage.size.width)), y: \(value[1] * Float(newImage.size.height)), width: \(value[2] * Float(newImage.size.width)), height: \(value[3] * Float(newImage.size.height))")
    let rect = CGRect(x: CGFloat(value[0] * Float(newImage.size.width)), y: CGFloat(value[1] * Float(newImage.size.height)), width: CGFloat(value[2] * Float(newImage.size.width)), height: CGFloat(value[3] * Float(newImage.size.height)))
    newImage = boundingBoxToImage(drawText: key, inImage: newImage, inRect: rect)
}

newImage = transformedImage!
for i in 0..<fakePos.count{
    let rect = CGRect(x: CGFloat(fakePos[i][0] * Float(newImage.size.width)), y: CGFloat(fakePos[i][1] * Float(newImage.size.height)), width: CGFloat(fakePos[i][2] * Float(newImage.size.width)), height: CGFloat(fakePos[i][3] * Float(newImage.size.height)))
    newImage = boundingBoxToImage(drawText: fakeArr[i], inImage: newImage, inRect: rect)
}

// MARK: - Setting up Vision Model
//let model = try VNCoreMLModel(for: last().model)
//let request = VNCoreMLRequest(model: model, completionHandler: myResultsMethod)
//let handler = VNImageRequestHandler(url: URL(fileURLWithPath: "test/blinds/IMG_3261.JPG"))
//try handler.perform([request])
//
//func myResultsMethod(request: VNRequest, error: Error?) {
//    guard let results = request.results as? [VNClassificationObservation]
//        else { fatalError("huh") }
//    for classification in results {
//        print(classification.confidence)
//    }
//}
