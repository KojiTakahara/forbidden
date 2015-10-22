import Foundation

class ImageUtil {
    
    /**
    URLから画像を取得する
    */
    class func getImageByUrl(img_url: String) -> UIImage {
        let url = NSURL(string: img_url);
        let imgData: NSData
        var image: UIImage = UIImage()
        do {
            imgData = try NSData(contentsOfURL:url!,options: NSDataReadingOptions.DataReadingMappedIfSafe)
            image = UIImage(data:imgData)!
        } catch {
            print("Error: can't create image.")
        }
        return image
    }
    
    /**
    文字を読みやすくするため、白黒にする
    */
    class func monocro(image: UIImage) -> UIImage {
        let ciImage = CIImage(image: image)
        let ciFilter = CIFilter(name: "CIColorMonochrome")
        ciFilter!.setValue(ciImage, forKey: kCIInputImageKey)
        ciFilter!.setValue(CIColor(red: 0.75, green: 0.75, blue: 0.75), forKey: kCIInputColorKey)
        ciFilter!.setValue(NSNumber(float: 1.0), forKey: kCIInputIntensityKey)
        let ciContext = CIContext(options: nil)
        let cgImage = ciContext.createCGImage(ciFilter!.outputImage!, fromRect: ciFilter!.outputImage!.extent)
        return UIImage(CGImage: cgImage)
    }
    
    /**
    切り取る
    */
    class func cropName(image: UIImage) -> UIImage {
        let origWidth  = Int(CGImageGetWidth(image.CGImage))
        let origHeight = Int(CGImageGetHeight(image.CGImage))
        let width = (origWidth / 10) * 6
        let height = (origHeight / 10) * 9
        let cropRect: CGRect = CGRectMake(
            CGFloat(width),
            CGFloat(height),
            CGFloat(origWidth),
            CGFloat(origHeight))
        let cropRef = CGImageCreateWithImageInRect(image.CGImage, cropRect)
        return UIImage(CGImage: cropRef!)
    }
    
    /**
    色の反転
    */
    class func colorInvert(originalImage: UIImage, context: CIContext) -> UIImage {
        let colorInvert = CIFilter(name: "CIColorInvert")
        return self.filterImage(originalImage, filter: colorInvert!, context: context)
    }
    
    /**
    画像の境界をシャープにする
    */
    class func unsharpMask(originalImage: UIImage, context: CIContext) -> UIImage {
        let unsharpMask = CIFilter(name: "CIUnsharpMask")
        return self.filterImage(originalImage, filter: unsharpMask!, context: context)
    }
    
    private class func filterImage(originalImage: UIImage, filter: CIFilter, context: CIContext) -> UIImage {
        let image = CIImage(image: originalImage)
        filter.setValue(image, forKey: kCIInputImageKey)
        let result = filter.valueForKey(kCIOutputImageKey) as! CIImage
        let rect = CGRect(origin: CGPointZero, size: originalImage.size)
        let resultRef = context.createCGImage(result, fromRect: rect)
        return UIImage(CGImage: resultRef)
    }
}