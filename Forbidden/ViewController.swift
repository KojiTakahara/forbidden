import UIKit
import AVFoundation

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, G8TesseractDelegate {
    
    var mySession: AVCaptureSession!
    var myDevice: AVCaptureDevice!
    var myImageOutput: AVCaptureVideoDataOutput!

    /**
    初期動作
    */
    override func viewDidLoad() {
        super.viewDidLoad()
        if initCamera() {
            // 画像を表示するレイヤーを生成.
            let myVideoLayer : AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer.init(session:mySession)
            myVideoLayer.frame = self.view.bounds
            myVideoLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
            // Viewに追加.
            self.view.layer.addSublayer(myVideoLayer)
            // 撮影開始
            mySession.startRunning()
        } else {
            var imageUrl = "http://dm.takaratomy.co.jp/wp-content/uploads/capture_revo01_dmr17-s08.jpg" // メガマナロック
            imageUrl = "http://livedoor.blogimg.jp/oregairu/imgs/5/c/5c6619b6.jpg" // ウィクロス
            imageUrl = "http://apostle18.up.n.seesaa.net/apostle18/image/image-ebf92.jpg?d=a2" // キングボルシャック
            var card = ImageUtil.getImageByUrl(imageUrl)
            card = self.processImage(card)
            self.analyze(card)
            self.createImageView(card)
        }
        self.showGridLine()
        self.createIndicator()
    }
    
    /**
    画像を加工する
    */
    func processImage(image: UIImage) -> UIImage {
        let context = CIContext(options: nil)
        var card = ImageUtil.cropName(image)
        card = ImageUtil.monocro(card)
        card = ImageUtil.colorInvert(card, context: context)
        card = ImageUtil.unsharpMask(card, context: context)
        card = ImageUtil.resize(card, ratio: 10)
        card = ImageUtil.highlightShadowAdjust(card, context: context)
        card = ImageUtil.exposureAdjust(card, context: context)
        return card
    }
    
    /**
    画像をビューに表示する
    */
    func createImageView(myImage: UIImage) {
        let myImageView: UIImageView = UIImageView()
        myImageView.frame = CGRectMake(0, 0, self.view.frame.size.width, 300)
        myImageView.contentMode = UIViewContentMode.ScaleAspectFit
        myImageView.image = myImage
        myImageView.layer.position = CGPoint(x: self.view.bounds.width/2, y: 200.0)
        self.view.addSubview(myImageView)
    }
    
    /**
    ビュー上に赤い枠線を描く
    */
    func showGridLine() {
        let myBoundSize: CGSize = UIScreen.mainScreen().bounds.size
        let width = myBoundSize.width
        let height = myBoundSize.height
        let grigLineView: UIView = UIView()
        grigLineView.frame = CGRectMake(width * 0.05, height * 0.15, width * 0.9, height * 0.7)
        grigLineView.layer.borderWidth = 4.0
        grigLineView.layer.borderColor = UIColor.redColor().CGColor
        grigLineView.layer.cornerRadius = 10.0
        self.view.addSubview(grigLineView)
    }
    

    var myActivityIndicator: UIActivityIndicatorView!
    
    func createIndicator() {
        // インジケータを作成する.
        myActivityIndicator = UIActivityIndicatorView()
        myActivityIndicator.frame = CGRectMake(0, 0, 50, 50)
        myActivityIndicator.center = self.view.center
        // アニメーションが停止している時もインジケータを表示させる.
        myActivityIndicator.hidesWhenStopped = false
        myActivityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.White
        // アニメーションを開始する.
        myActivityIndicator.startAnimating()
        // インジケータをViewに追加する.
        self.view.addSubview(myActivityIndicator)
    }
    
    /**
    カメラの準備処理
    */
    func initCamera() -> Bool {
        // セッションの作成.
        mySession = AVCaptureSession()
        // 解像度の指定.
        mySession.sessionPreset = AVCaptureSessionPresetPhoto
        // デバイス一覧の取得.
        let devices = AVCaptureDevice.devices()
        // バックカメラをmyDeviceに格納.
        for device in devices{
            if(device.position == AVCaptureDevicePosition.Back){
                myDevice = device as! AVCaptureDevice
            }
        }
        if myDevice == nil { // 格納できなければ終わり
            return false
        }
        // バックカメラからVideoInputを取得.
        let videoInput: AVCaptureInput!
        do {
            videoInput = try AVCaptureDeviceInput.init(device: myDevice!)
        } catch {
            videoInput = nil
        }
        // セッションに追加.
        if mySession.canAddInput(videoInput) {
            mySession.addInput(videoInput)
        } else {
            return false
        }
        // 出力先を生成.
        myImageOutput = AVCaptureVideoDataOutput()
        myImageOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey: Int(kCVPixelFormatType_32BGRA)]
        // FPSを設定
//        var lockError: NSError?
//        if myDevice.lockForConfiguration(&lockError) {
//            if let error = lockError {
//                println("lock error: \(error.localizedDescription)")
//                return false
//            } else {
//                myDevice.activeVideoMinFrameDuration = CMTimeMake(1, 15)
//                myDevice.unlockForConfiguration()
//            }
//        }
        // デリゲートを設定.
        let queue: dispatch_queue_t = dispatch_queue_create("myqueue",  nil)
        myImageOutput.setSampleBufferDelegate(self, queue: queue)
        // 遅れてきたフレームは無視する.
        myImageOutput.alwaysDiscardsLateVideoFrames = true
        // セッション開始.
        if mySession.canAddOutput(myImageOutput) {
            mySession.addOutput(myImageOutput)
        } else {
            return false
        }
        // カメラの向きを合わせる.
        for connection in myImageOutput.connections {
            if let conn = connection as? AVCaptureConnection {
                if conn.supportsVideoOrientation {
                    conn.videoOrientation = AVCaptureVideoOrientation.Portrait
                }
            }
        }
        return true
    }
    
    var flag = true
    
    /**
    毎フレーム実行される処理
    */
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        dispatch_async(dispatch_get_main_queue(), {
            var image = CameraUtil.imageFromSampleBuffer(sampleBuffer)
            if (self.flag) {
                self.myActivityIndicator.startAnimating()
                self.flag = false
                image = self.processImage(image)
                self.analyze(image)
            }
        })
    }
    
    /**
    文字読み取り
    */
    func analyze(image: UIImage) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), {
            let tesseract = G8Tesseract(language: "eng")
            tesseract.delegate = self
            tesseract.image = image
            tesseract.pageSegmentationMode = G8PageSegmentationMode.Auto
            tesseract.recognize()
            let recognizedText = tesseract.recognizedText
            if !self.blank(recognizedText) {
                print(recognizedText)
                let alertController = self.createActionSheet("", message: recognizedText)
                self.presentViewController(alertController, animated: true, completion: nil)
            }
            self.flag = true
            self.myActivityIndicator.stopAnimating()
        })
    }
    

    func blank(text: String) -> Bool {
        let trimmed = text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        return trimmed.isEmpty
    }
    
    func createActionSheet(title: String, message: String) -> UIAlertController {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        let defaultAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
        alertController.addAction(defaultAction)
        return alertController
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}

