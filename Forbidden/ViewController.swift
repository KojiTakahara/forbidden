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
            let imageUrl = "http://dm.takaratomy.co.jp/wp-content/uploads/capture_revo01_dmr17-s08.jpg"
            var card = ImageUtil.getImageByUrl(imageUrl)
            card = self.processImage(card)
            self.analyze(card)
            self.createImageView(card)
        }
    }
    
    /**
    画像を加工する
    */
    func processImage(image: UIImage) -> UIImage {
        let context = CIContext(options: nil)
        var card = ImageUtil.cropName(image)
        card = ImageUtil.monocro(card)
        //card = ImageUtil.colorInvert(card, context: context)
        //card = ImageUtil.unsharpMask(card, context: context)
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
    
    var myButton: UIButton!
    
    func addButton() {
        // UIボタンを作成.
        myButton = UIButton(frame: CGRectMake(0,0,120,50))
        myButton.backgroundColor = UIColor.redColor();
        myButton.layer.masksToBounds = true
        myButton.setTitle("読込中", forState: .Normal)
        myButton.layer.cornerRadius = 20.0
        myButton.layer.position = CGPoint(x: self.view.bounds.width/2, y:self.view.bounds.height-50)
        // UIボタンをViewに追加.
        self.view.addSubview(myButton);
    }

    func removeButton() {
        myButton.removeFromSuperview()
    }
    
    /**
    カメラの準備処理
    */
    func initCamera() -> Bool {
        // セッションの作成.
        mySession = AVCaptureSession()
        // 解像度の指定.
        //mySession.sessionPreset = AVCaptureSessionPresetPhoto
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
            print(tesseract.recognizedText)
            self.flag = true
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}

