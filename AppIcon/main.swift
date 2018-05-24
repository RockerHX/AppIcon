//
//  main.swift
//  AppIcon
//
//  Created by RockerHX on 2018/5/21.
//  Copyright © 2018年 RockerHX. All rights reserved.
//


import Foundation

// Default Input PNG
let DefaultPNGName = "AppIcon.png"
let AppiconsetFileName = "AppIcon.appiconset"
let ContentJSONFileName = "Contents.json"

/// Contents.json
let iPhoneContentsJSON =
"""
{
"images" : [
    {
        "size" : "20x20",
        "idiom" : "iphone",
        "filename" : "AppIcon-20@2x.png",
        "scale" : "2x"
    },
    {
        "size" : "20x20",
        "idiom" : "iphone",
        "filename" : "AppIcon-20@3x.png",
        "scale" : "3x"
    },
    {
        "size" : "29x29",
        "idiom" : "iphone",
        "filename" : "AppIcon-29@2x.png",
        "scale" : "2x"
    },
    {
        "size" : "29x29",
        "idiom" : "iphone",
        "filename" : "AppIcon-29@3x.png",
        "scale" : "3x"
    },
    {
        "size" : "40x40",
        "idiom" : "iphone",
        "filename" : "AppIcon-40@2x.png",
        "scale" : "2x"
    },
    {
        "size" : "40x40",
        "idiom" : "iphone",
        "filename" : "AppIcon-120.png",
        "scale" : "3x"
    },
    {
        "idiom" : "iphone",
        "size" : "60x60",
        "filename" : "AppIcon-120.png",
        "scale" : "2x"
    },
    {
        "size" : "60x60",
        "idiom" : "iphone",
        "filename" : "AppIcon-60@3x.png",
        "scale" : "3x"
    },
    {
        "size" : "1024x1024",
        "idiom" : "ios-marketing",
        "filename" : "AppIcon.png",
        "scale" : "1x"
    }
    ],
    "info" : {
        "version" : 1,
        "author" : "xcode"
    }
}
"""

struct AppIcon: Codable {

    var images: [Image]
    let info: Info

}


extension AppIcon {

    struct Image: Codable {
        let size: String
        let idiom: Idiom
        let filename: String
        let scale: Scale
        let role: String?
        let subtype: String?
    }

}

extension AppIcon.Image {

    enum Idiom: String, Codable {
        case iPhone = "iphone"
        case iPad = "ipad"
        case appleWatch = "watch"
        case mac = "mac"
        case carPlay = "car"
        case iOSMarketing = "ios-marketing"
        case unknown = "unknown"
    }

    enum Scale: String, Codable {
        case s1x = "1x"
        case s2x = "2x"
        case s3x = "3x"
    }

}


extension AppIcon.Image {

    func info() -> (size: CGSize, scale: CGFloat)? {
        let sizeStrs  = size.components(separatedBy: "x")
        let scaleStrs = scale.rawValue.components(separatedBy: "x")
        if  let width = sizeStrs.first,
            let height = sizeStrs.last,
            let scale  = scaleStrs.first {
            let widthInt  = CGFloat(Double(width) ?? 0)
            let heightInt = CGFloat(Double(height) ?? 0)
            let scaleInt  = CGFloat(Double(scale) ?? 0)
            return (.init(width: widthInt, height: heightInt), scaleInt)
        }
        return nil
    }

}


extension AppIcon {

    struct Info: Codable {
        let version: Int
        let author: String
    }

}


typealias DeviceType = AppIcon.Image.Idiom
extension DeviceType {

    init(with index: String) {
        switch index {
        case "1":
            self = .iPhone
        case "2":
            self = .iPad
        case "3":
            self = .appleWatch
        case "4":
            self = .mac
        case "5":
            self = .carPlay
        default:
            self = .unknown
        }
    }

    static func type(with selects: String) -> [DeviceType] {
        var types = [DeviceType]()
        var indexs = selects.components(separatedBy: ",")
        indexs = Array(Set(indexs))
        indexs.forEach { (index) in
            types.append(DeviceType(with: index))
        }
        return types
    }
    
}


extension CGImage {

    /// Get Image resolution
    func resolution() -> (width: Int, height: Int) {
        let width  = self.width
        let height = self.height
        print("resolution: \(width) * \(height)\n")
        return (width, height)
    }

}


/// Valid Image Resolution
///
/// - Parameter: Images resolution
/// - Returns: Valid or Invalid
func validImage(resolution: (width: Int, height: Int)) -> Bool {
    if resolution.width < 1024 || resolution.height < 1024 { return false }
    return true
}


/// Generate ContentsJson
///
/// - Parameter: AppIcon
func generateContentsJson(appIcon: AppIcon) {
    print("\n Start generate Contents JSON\n")
    let encoder = JSONEncoder()
    do {
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(appIcon)
        if let content = String(data: data, encoding: .utf8) {
            let path = "\(AppiconsetFileName)/\(ContentJSONFileName)"
            let url = URL(fileURLWithPath: path)
            try content.write(to: url, atomically: true, encoding: .utf8)
            print("✅ Contents JSON generate success!\n")
        } else {
            print("❌ Contents JSON generate failure!")
        }
    } catch {
        print(error)
    }
}


/// Generate Image
///
/// - Parameters:
///   - size: image size
///   - scale: image scale
///   - image: origin image
///   - filename: generate image file name
func generateImage(size: CGSize, scale: CGFloat, image: CGImage, filename: String) {
    print("Start generate image: \(filename)")
    let width  = Int(size.width * scale)
    let height = Int(size.height * scale)
    let bitsPerComponent = image.bitsPerComponent
//    let bytesPerRow = image.bytesPerRow
    let colorSpace  = CGColorSpaceCreateDeviceRGB()

    if let context = CGContext(data: nil,
                              width: width,
                             height: height,
                   bitsPerComponent: bitsPerComponent,
                        bytesPerRow: 0,
                              space: colorSpace,
                         bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
    {
        context.interpolationQuality = .high
        context.draw(image, in: .init(origin: .zero, size: .init(width: width, height: height)))
        if let outputImage = context.makeImage() {
            let outputImagePath = "\(AppiconsetFileName)/\(filename)"
            let outputUrl = URL(fileURLWithPath: outputImagePath) as CFURL
            let destination = CGImageDestinationCreateWithURL(outputUrl, kUTTypePNG, 1, nil)
            if let destination = destination {
                CGImageDestinationAddImage(destination, outputImage, nil)
                if CGImageDestinationFinalize(destination) {
                    print("✅ Image: \(filename) generate success.\n")
                } else {
                    print("❌ Image: \(filename) generate failure.\n")
                }
            }
        } else {
            print("❌ Image: \(filename) generate failure.\n")
        }
    }
}


/// Generate Images
///
/// - Parameter: AppIcon
func generateImages(appIcon: AppIcon, image: CGImage) {
    print("Start generate images\n")
    for img in appIcon.images {
        if let info = img.info() {
            generateImage(size: info.size, scale: info.scale, image: image, filename: img.filename)
        } else {
            let encoder = JSONEncoder()
            do {
                encoder.outputFormatting = .prettyPrinted
                let data = try encoder.encode(img)
                if let json  = String(data: data, encoding: .utf8) {
                    print("❌ json format erro: \(json)")
                } else {
                    print("❌ json format error")
                }
            } catch {
                print(error)
            }
        }
    }
}


/// Generate Appiconset
///
/// - Parameter: AppIcon
func generateAppiconset(with appIcon: AppIcon, image: CGImage) {
    let fileManager = FileManager.default
    let filePath = AppiconsetFileName
    do {
        if fileManager.fileExists(atPath: filePath) {
            try fileManager.removeItem(atPath: filePath)
        }
        try fileManager.createDirectory(atPath: filePath, withIntermediateDirectories: true, attributes: nil)
        generateContentsJson(appIcon: appIcon)
        generateImages(appIcon: appIcon, image: image)
        print("**************** Done ****************")
    } catch {
        print("❌ \(filePath) create failure.")
        print(error)
    }
}


/// Generate Appiconsets
///
/// - Parameter: AppIcons
/// - Parameter: image
func generateAppiconsets(with appIcons: [AppIcon], image: CGImage) {
    appIcons.forEach { (appIcon) in
        generateAppiconset(with: appIcon, image: image)
    }
}


/// Generate AppIcons by type
///
/// - Parameter: input type
/// - Returns: AppIcon
func generateAppIcon(with json: String) -> AppIcon? {
    if let jsonData = json.data(using: .utf8) {
        let decoder = JSONDecoder()
        do {
            let appIcon = try decoder.decode(AppIcon.self, from: jsonData)
            return appIcon
        } catch {
            print("❌ JSON parse failure: \(error)")
        }
    } else {
        print("❌ JSON parse failure.")
    }
    return nil
}


/// Generate AppIcons by types
///
/// - Parameter: input types
/// - Returns: AppIcon
func generateAppIcons(with types: String) -> [AppIcon] {
    var appIcons = [AppIcon]()
    let deviceTypes = DeviceType.type(with: types)
    deviceTypes.forEach { (deviceType) in
        var content = ""
        switch deviceType {
        case .iPhone:
            content = iPhoneContentsJSON
        case .iPad:
            content = ""
        case .appleWatch:
            content = ""
        case .mac:
            content = ""
        case .carPlay:
            content = ""
        default:
            break
        }
        guard let appIcon = generateAppIcon(with: content) else { return }
        appIcons.append(appIcon)
    }
    return appIcons
}


/// Select AppIcon Type
func selectAppIconType(with image: CGImage) {
    print(
        """
        Please enter the number of the icon you want to convert (can be multiplexed, separated by a number, for example: 1,2,3, the default is 1):
        1.iPhone
        2.iPad
        3.AppleWatch
        4.Mac
        5.CarPlay
        """
    )
    if var types = readLine() {
        if types.isEmpty {
            types = "1"
        }
        let appIcons = generateAppIcons(with: types)
        if !appIcons.isEmpty {
            generateAppiconsets(with: appIcons, image: image)
        } else {
            print("❌ The type of input is in the wrong format. Please enter eg: 1,2,3")
        }
    } else {
        print("❌ Get type failure.")
    }
}


func loadImage(with url: URL) {
    do {
        let inoutData = try Data(contentsOf: url)
        print("Image size: \(inoutData.count / 1000) kb")

        let dataProvider = CGDataProvider(data: inoutData as CFData)
        if let inputImage = CGImage(pngDataProviderSource: dataProvider!,
                                                   decode: nil,
                                        shouldInterpolate: true,
                                                   intent: .defaultIntent)
        {
            if validImage(resolution: inputImage.resolution()) {
                selectAppIconType(with: inputImage)
            } else {
                print("❌ The resolution of the picture cannot be less than 1024x1024.")
            }
        } else {
            print("❌ Conversion failed, image must be in png.")
        }
    } catch {
        print(error)
    }
}


func start() {
    print(
        """
        ***********************************************************
        *      ___   _____   _____   _   _____   _____   __   _   *
        *     /   | |  _  \\ |  _  \\ | | /  ___| /  _  \\ |  \\ | |  *
        *    / /| | | |_| | | |_| | | | | |     | | | | |   \\| |  *
        *   / / | | |  ___/ |  ___/ | | | |     | | | | | |\\   |  *
        *  / /  | | | |     | |     | | | |___  | |_| | | | \\  |  *
        * /_/   |_| |_|     |_|     |_| \\_____| \\_____/ |_|  \\_|  *
        *                                                         *
        *           Github: https://github.com/RockerHX           *
        *                                                         *
        ***********************************************************
        """
    )

    print("Input your PNG name（Default is \(DefaultPNGName)）:")
    if var inputPath = readLine() {
        if inputPath.isEmpty {
            inputPath = DefaultPNGName
        }
        let url = URL(fileURLWithPath: inputPath)
        loadImage(with: url)
    } else {
        print("❌ Load failure.")
    }
}


start()

