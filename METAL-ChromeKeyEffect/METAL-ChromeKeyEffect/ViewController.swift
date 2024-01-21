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
    private let downloadPath : String = "https://metalpetal-awsbucket.s3.eu-north-1.amazonaws.com/chromaTiger.mp4"
    
    var player: AVPlayer?
    var playerLayer: AVPlayerLayer?
    var videoURL: URL?
    
    var context: MTIContext?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(self.playerDidFinishPlaying), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
        ImagePickerManager.shared.delegate = self
        self.downloadVideo()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer?.frame = videoView.bounds
    }
    
    private func downloadVideo() {
        DownloadManager.shared.downloadFile(from: downloadPath) { [weak self] savedURL, error in
            guard let self else { return }
            if let savedURL = savedURL {
                self.videoURL = savedURL
            } else if let error = error {
                debugPrint("Error downloading file: \(error)")
            }
        }
    }
    
    @IBAction func selectBackgroundButtonAction(_ sender: Any) {
        ImagePickerManager.shared.presentImagePicker(from: self)
    }
    
    func applyChromaKeyEffect(to image: UIImage) {
        guard let videoURL else { return }
        self.selectBackgroundButtonOutlet.isEnabled = false
        self.selectBackgroundButtonOutlet.layer.opacity = 0.1
        ChromaKeyFilter.shared.applyChroma(with: image, from: videoURL, to: self.videoView)
    }
     
    @objc private func playerDidFinishPlaying() {
        self.selectBackgroundButtonOutlet.isEnabled = true
        self.selectBackgroundButtonOutlet.layer.opacity = 1
        ChromaKeyFilter.shared.dispose()
    }
}


extension ViewController : ImagePickerDelegate {
    func didSelect(image: UIImage?) {
        guard let image else { return }
        self.applyChromaKeyEffect(to: image)
    }
}
