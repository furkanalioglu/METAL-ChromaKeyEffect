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
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
        guard let videoURL = videoURL else { return }
        self.exportImagesFromVideoWithMetalPetal(url: videoURL) { [weak self] result in
            switch result {
            case .success(let images):
                print("images count is \(images.count)")
            case .failure(let err):
                print("Error exporting images: \(err)")
            }
        }
    }

    private func animateImages(_ images: [UIImage]) {
        let animationImageView = UIImageView(frame: videoView.bounds)
        videoView.addSubview(animationImageView)
        animationImageView.animationImages = images
        animationImageView.animationDuration = Double(images.count) / 30 // Assuming 30 frames per second
        animationImageView.startAnimating()
    }
    
    private func exportImagesFromVideoWithMetalPetal(url: URL, completion: @escaping (Result<[UIImage], Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let asset = AVAsset(url: url)
            asset.loadTracks(withMediaType: .video) { tracks, error in
                guard let videoTrack = tracks?.first else {
                    DispatchQueue.main.async {
                        completion(.failure(error ?? NSError(domain: "Failed to load video tracks", code: 0, userInfo: nil)))
                    }
                    return
                }

                do {
                    let assetReader = try AVAssetReader(asset: asset)
                    let assetReaderOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: [String(kCVPixelBufferPixelFormatTypeKey): kCVPixelFormatType_32BGRA])
                    assetReader.add(assetReaderOutput)
                    assetReader.startReading()

                    var images = [UIImage]()
                    let context = try MTIContext(device: MTLCreateSystemDefaultDevice()!)

                    while let sampleBuffer = assetReaderOutput.copyNextSampleBuffer(), assetReader.status == .reading {
                        if let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
                            let mtiImage = MTIImage(cvPixelBuffer: imageBuffer, alphaType: .alphaIsOne)
                            if let cgImage = try? context.makeCGImage(from: mtiImage) {
                                let uiImage = UIImage(cgImage: cgImage)
                                images.append(uiImage)
                            }
                        }
                    }

                    DispatchQueue.main.async {
                        if assetReader.status == .completed {
                            completion(.success(images))
                        } else if assetReader.status == .failed || assetReader.status == .cancelled {
                            completion(.failure(NSError(domain: "Failed to read all frames", code: 0, userInfo: nil)))
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                }
            }
        }
    }


    
}

