//
//  ImagePickerManager.swift
//  METAL-ChromeKeyEffect
//
//  Created by Furkan Alioglu on 20.01.2024.
//

import Foundation
import UIKit

protocol ImagePickerDelegate : AnyObject {
    func didSelect(image: UIImage?)
}

class ImagePickerManager:NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    static let shared = ImagePickerManager()
    
    
    private var picker = UIImagePickerController()
    weak var delegate: ImagePickerDelegate?
    private weak var presentingViewController: UIViewController?
    
    private override init() {
        super.init()
        picker.delegate = self
        picker.sourceType = .savedPhotosAlbum
        picker.allowsEditing = false
    }
    
    func presentImagePicker(from vc: UIViewController) {
        self.presentingViewController = vc
        vc.present(picker, animated: true,completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
        delegate?.didSelect(image: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        let image = info[.originalImage] as? UIImage
        delegate?.didSelect(image: image)
    }
    
}
