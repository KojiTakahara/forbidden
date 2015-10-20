import UIKit
import AVFoundation

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, G8TesseractDelegate {
    
    var mySession : AVCaptureSession!
    var myDevice : AVCaptureDevice!
    var myImageOutput : AVCaptureVideoDataOutput!

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
        }
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
    
    /**
    毎フレーム実行される処理
    */
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        dispatch_async(dispatch_get_main_queue(), {
            let image = CameraUtil.imageFromSampleBuffer(sampleBuffer)
            self.analyze(image)
        })
    }
    
    func analyze(image: UIImage) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), {
            let tesseract = G8Tesseract(language: "jpn")
            tesseract.delegate = self
            tesseract.image = image
            tesseract.pageSegmentationMode = G8PageSegmentationMode.Auto
            tesseract.recognize()
            print(tesseract.recognizedText)
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}

