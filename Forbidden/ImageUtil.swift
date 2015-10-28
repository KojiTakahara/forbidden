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
    比率を指定してリサイズ
    */
    class func resize(image: UIImage, ratio: CGFloat) -> UIImage {
        let resizedSize = CGSize(width: Int(image.size.width * ratio), height: Int(image.size.height * ratio))
        UIGraphicsBeginImageContext(resizedSize)
        image.drawInRect(CGRect(x: 0, y: 0, width: resizedSize.width, height: resizedSize.height))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage
    }
    
    /**
    色の反転
    */
    class func colorInvert(originalImage: UIImage, context: CIContext) -> UIImage {
        let colorInvert = CIFilter(name: "CIColorInvert")
        return self.filterImage(originalImage, filter: colorInvert!, context: context)
    }
    
    /**
    shadow
    */
    class func highlightShadowAdjust(originalImage: UIImage, context: CIContext) -> UIImage {
        let filter = CIFilter(name: "CIHighlightShadowAdjust")
        filter?.setValue(0.5, forKey: "inputShadowAmount")
        filter?.setValue(1, forKey: "inputHighlightAmount")
        return self.filterImage(originalImage, filter: filter!, context: context)
    }
    
    /**
    CIEdgeWork
    */
    class func edgeWork(originalImage: UIImage, context: CIContext) -> UIImage {
        let filter = CIFilter(name: "CIEdgeWork")
        filter?.setValue(0.1, forKey: "inputRadius")
        return self.filterImage(originalImage, filter: filter!, context: context)
    }
    
    /**
    CIColorControls
    */
    class func colorControls(originalImage: UIImage, context: CIContext) -> UIImage {
        let filter = CIFilter(name: "CIColorControls")
        return self.filterImage(originalImage, filter: filter!, context: context)
    }
    
    /**
    CIExposureAdjust
    */
    class func exposureAdjust(originalImage: UIImage, context: CIContext) -> UIImage {
        let filter = CIFilter(name: "CIExposureAdjust")
        filter?.setValue(1, forKey: "inputEV")
        return self.filterImage(originalImage, filter: filter!, context: context)
    }
    
    /**
    CILineOverlay
    */
    class func lineOverlay(originalImage: UIImage, context: CIContext) -> UIImage {
        let filter = CIFilter(name: "CILineOverlay")
        filter?.setValue(0.91, forKey: "inputNRNoiseLevel")
        filter?.setValue(0.91, forKey: "inputNRSharpness")
        filter?.setValue(100, forKey: "inputContrast")
        return self.filterImage(originalImage, filter: filter!, context: context)
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