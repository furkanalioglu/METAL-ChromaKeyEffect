//
//  MetalBlendManager.swift
//  METAL-ChromeKeyEffect
//
//  Created by Furkan Alioglu on 20.01.2024.
//

import Foundation
import MetalPetal

class MetalBlendManager {
    static let shared = MetalBlendManager()
    var processedImages = [MTIImage]()
    
    func applyChromaKeyFilter(to inputImages: [UIImage], withBackgroundImageName backgroundImageName: String) {
        guard let backgroundImage = UIImage(named: backgroundImageName) else {
            print("Failed to load background image")
            return
        }
        
        let backgroundImageMTI = MTIImage(image: backgroundImage, isOpaque: true)
        let chromaKeyFilter = MTIChromaKeyBlendFilter()
        chromaKeyFilter.inputBackgroundImage = backgroundImageMTI
        
        for uiImage in inputImages {
            let inputMTIImage = MTIImage(image: uiImage, isOpaque: true)
                chromaKeyFilter.inputImage = inputMTIImage
                
                if let outputImage = chromaKeyFilter.outputImage {
                    processedImages.append(outputImage)
            }
        }
    }
}
