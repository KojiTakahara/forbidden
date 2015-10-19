import Foundation
import UIKit
import AVFoundation

class CameraUtil {
    
    /**
    sampleBufferからUIImageへ変換
    */
    class func imageFromSampleBuffer(sampleBuffer: CMSampleBufferRef) {// -> UIImage {
        let imageBuffer: CVImageBufferRef = CMSampleBufferGetImageBuffer(sampleBuffer)!
        // ベースアドレスをロック
        CVPixelBufferLockBaseAddress(imageBuffer, 0)
        // 画像データの情報を取得
        let baseAddress: UnsafeMutablePointer<Void> = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0)
        let bytesPerRow: Int = CVPixelBufferGetBytesPerRow(imageBuffer)
        let width: Int = CVPixelBufferGetWidth(imageBuffer)
        let height: Int = CVPixelBufferGetHeight(imageBuffer)
        // RGB色空間を作成
        let colorSpace: CGColorSpaceRef = CGColorSpaceCreateDeviceRGB()!
        // Bitmap graphic contextを作成
        let bitsPerCompornent = 8
        let rawValue = CGBitmapInfo.ByteOrder32Little.rawValue | CGImageAlphaInfo.PremultipliedFirst.rawValue
        let bitmapInfo = CGBitmapInfo(rawValue: rawValue)
        let context = CGBitmapContextCreate(baseAddress, width, height, bitsPerCompornent, bytesPerRow, colorSpace, bitmapInfo.rawValue)
        print(context)
        // Quartz imageを作成
//        let imageRef: CGImageRef = CGBitmapContextCreateImage(context)!
//        // UIImageを作成
//        return UIImage(CGImage: imageRef)
    }
    
}