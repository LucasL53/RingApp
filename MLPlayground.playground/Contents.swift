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
    /// Resize image while keeping the aspect ratio. Original image is not modified.
    /// - Parameters:
    ///   - width: A new width in pixels.
    ///   - height: A new height in pixels.
    /// - Returns: Resized image.
    func resize(_ width: Int, _ height: Int) -> UIImage {
        // Keep aspect ratio
        let maxSize = CGSize(width: width, height: height)

        let availableRect = AVFoundation.AVMakeRect(
            aspectRatio: self.size,
            insideRect: .init(origin: .zero, size: maxSize)
        )
        let targetSize = availableRect.size

        // Set scale of renderer so that 1pt == 1px
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)

        // Resize the image
        let resized = renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: targetSize))
        }

        return resized
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
let image = UIImage(named: "test/lights_2/IMG_3243.JPG")
//let newimage = centerImageOnBlackSquare(image: image!, squareSize: CGSize(width: 160, height: 160))
let buffer = (image?.convertToBuffer())!
let address = CVPixelBufferGetDataSize(buffer)
let resized_buffer = resize(pixelBuffer: (image?.convertToBuffer())!, width: 160, height: 160)
let resized_buffer_size = CVPixelBufferGetDataSize(resized_buffer!)
let transformedImage = UIImage(pixelBuffer: buffer)
//let colors = transformedImage!.colors
let result = try! last().prediction(image: resized_buffer!, iouThreshold: 0.4, confidenceThreshold: 0.1)
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
    for j in 0..<classConfidence.shape[1].intValue {
        let index = [NSNumber(value: i), NSNumber(value: j)]
        let value = classConfidence[index].floatValue
         print("Value at [\(i), \(j),]: \(value)")
        if maxValue < value {
            maxValue = value
            maxIndex = j
        }
    }
    fakeArr.append(labels[maxIndex])
    
    print("Predicted \(labels[maxIndex]) at confidence \(maxValue)")
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
print("map contains: \(classMap.keys), \(classMap.values)")
var newImage = transformedImage!
for (key, value) in classMap {
    print("x: \(value[0] * Float(newImage.size.width)), y: \(value[1] * Float(newImage.size.height)), width: \(value[2] * Float(newImage.size.width)), height: \(value[3] * Float(newImage.size.height))")
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
