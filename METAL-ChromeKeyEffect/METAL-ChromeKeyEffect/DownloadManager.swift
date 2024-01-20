//
//  DownloadManager.swift
//  METAL-ChromeKeyEffect
//
//  Created by Furkan Alioglu on 20.01.2024.
//

import Foundation

class DownloadManager {

    static let shared = DownloadManager()
    
    private init() {}

    func downloadFile(from urlString: String, completion: @escaping (URL?, Error?) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(nil, NSError(domain: "Invalid URL", code: 0, userInfo: nil))
            return
        }

        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationURL = documentsPath.appendingPathComponent(url.lastPathComponent)

        // Check if file already exists at destinationURL
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            print("File already exists at location \(destinationURL)")
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                completion(destinationURL, nil)
            }
            return
        }

        let task = URLSession.shared.downloadTask(with: url) { localURL, response, error in
            if let localURL = localURL {
                do {
                    try FileManager.default.moveItem(at: localURL, to: destinationURL)
                    print("File saved to location \(destinationURL)")
                    DispatchQueue.main.async {
                        completion(destinationURL, nil)
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(nil, error)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
            }
        }

        task.resume()
    }

}
