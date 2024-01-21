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

        if FileManager.default.fileExists(atPath: destinationURL.path) {
            debugPrint("File already exists at location \(destinationURL)")
            DispatchQueue.main.async { [weak self] in
                guard self != nil else { return }
                completion(destinationURL, nil)
            }
            return
        }

        let task = URLSession.shared.downloadTask(with: url) { localURL, response, error in
            if let localURL = localURL {
                do {
                    try FileManager.default.moveItem(at: localURL, to: destinationURL)
                    debugPrint("File saved to location \(destinationURL)")
                    DispatchQueue.main.async { [weak self] in
                        guard self != nil else { return }
                        completion(destinationURL, nil)
                    }
                } catch {
                    DispatchQueue.main.async { [weak self] in
                        guard self != nil else { return }
                        completion(nil, error)
                    }
                }
            } else {
                DispatchQueue.main.async { [weak self] in
                    guard self != nil else { return }
                    completion(nil, error)
                }
            }
        }

        task.resume()
    }

}
