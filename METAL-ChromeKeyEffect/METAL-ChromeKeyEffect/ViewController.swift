//
//  ViewController.swift
//  METAL-ChromeKeyEffect
//
//  Created by Furkan Alioglu on 20.01.2024.
//

import UIKit
import AVFoundation
import MetalPetal

class ViewController: UIViewController {
    @IBOutlet weak var selectBackgroundButtonOutlet: UIButton!
    @IBOutlet weak var videoView: UIView!
    
    private var metalContext: MTIContext!
    
    var player: AVPlayer?
    var playerLayer: AVPlayerLayer?
    var videoURL: URL?
    
    var context: MTIContext?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ImagePickerManager.shared.delegate = self
        self.downloadVideo()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer?.frame = videoView.bounds
    }
    
    private func downloadVideo() {
        DownloadManager.shared.downloadFile(from: "https://metalpetal-awsbucket.s3.eu-north-1.amazonaws.com/chromaTiger.mp4") { [weak self] savedURL, error in
            guard let self else { return }
            if let savedURL = savedURL {
                self.videoURL = savedURL
            } else if let error = error {
                print("Error downloading file: \(error)")
            }
        }
    }
    
    
    @IBAction func selectBackgroundButtonAction(_ sender: Any) {
        ImagePickerManager.shared.presentImagePicker(from: self)
    }
    
    private func applyChroma(with image: UIImage?) {
        do{
            context = try MTIContext(device: MTLCreateSystemDefaultDevice()!)
        }catch {
            print("failed to create context")
        }
        
        guard let backImage = image?.cgImage,
              let context else { return }
        
        let backgroundMTI = MTIImage(cgImage: backImage, options: [.SRGB: false], isOpaque: true)
        guard let videoURL else { return }
        let asset = AVAsset(url: videoURL)
        
        let composition = MTIVideoComposition(asset: asset, context: context, queue: .main) { request in
            let filter = MTIChromaKeyBlendFilter()
            filter.inputImage = request.anySourceImage
            filter.inputBackgroundImage = backgroundMTI
            filter.thresholdSensitivity = 0.4
            filter.smoothing = 0.1
            filter.color = MTIColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 1.0)
            return filter.outputImage!
        }
        
        let playerItem = AVPlayerItem(asset: asset)
        playerItem.videoComposition = composition.makeAVVideoComposition()
        
        self.player = AVPlayer(playerItem: playerItem)
        playerLayer = AVPlayerLayer(player:player)
        playerLayer?.frame = videoView.bounds
        playerLayer?.videoGravity = .resizeAspectFill
        videoView.layer.addSublayer(playerLayer!)
        player?.play()
    }
    
}


extension ViewController : ImagePickerDelegate {
    func didSelect(image: UIImage?) {
        guard let image else { return }
        self.applyChroma(with: image)
    }
}
