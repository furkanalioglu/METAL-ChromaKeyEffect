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
    
    var player: AVPlayer?
    var playerLayer: AVPlayerLayer?
    var videoURL: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.downloadVideo()
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
            exportImagesFromVideoAndSave(url: videoURL) { result in
                switch result {
                case .success(let urls):
                    print("Images saved at URLs: \(urls)")
                case .failure(let error):
                    print("Error exporting images: \(error)")
            }
        }
    }
    
    private func exportImagesFromVideoAndSave(url: URL, completion: @escaping (Result<[URL], Error>) -> Void) {
        let asset = AVAsset(url: url)
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]

        asset.loadTracks(withMediaType: .video) { tracks, error in
            guard let videoTrack = tracks?.first else {
                completion(.failure(error ?? NSError(domain: "Failed to load video tracks", code: 0, userInfo: nil)))
                return
            }

            do {
                let assetReader = try AVAssetReader(asset: asset)
                let assetReaderOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: [String(kCVPixelBufferPixelFormatTypeKey): kCVPixelFormatType_32BGRA])
                assetReader.add(assetReaderOutput)
                assetReader.startReading()

                var outputURLs = [URL]()
                var frameCount = 0

                while let sampleBuffer = assetReaderOutput.copyNextSampleBuffer(), assetReader.status == .reading {
                    if let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
                        let ciImage = CIImage(cvImageBuffer: imageBuffer)
                        let context = CIContext()
                        if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
                            let frameURL = documentsURL.appendingPathComponent("frame_\(frameCount).jpg")
                            if let data = UIImage(cgImage: cgImage).jpegData(compressionQuality: 0.8) {
                                try data.write(to: frameURL)
                                outputURLs.append(frameURL)
                                frameCount += 1
                            }
                        }
                    }
                }

                if assetReader.status == .completed {
                    completion(.success(outputURLs))
                } else if assetReader.status == .failed || assetReader.status == .cancelled {
                    completion(.failure(NSError(domain: "Failed to read all frames", code: 0, userInfo: nil)))
                }

            } catch {
                completion(.failure(error))
            }
        }
    }

    
    private func exportImagesFromVideo(for asset: AVAsset) -> AVVideoComposition {
        let composition = AVVideoComposition(asset: asset) { request in
            request.finish(with: request.sourceImage, context: nil)
        }
        return composition
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer?.frame = videoView.bounds
    }
    
}

