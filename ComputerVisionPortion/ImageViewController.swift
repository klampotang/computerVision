//
//  ImageViewController.swift
//  ComputerVisionPortion
//
//  Created by Kelly Lampotang on 7/19/16.
//  Copyright © 2016 Kelly Lampotang. All rights reserved.
//

import UIKit

class ImageViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    private lazy var client : ClarifaiClient = ClarifaiClient(appID: clarifaiClientID, appSecret: clarifaiClientSecret)

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var tagsLabel: UILabel!
    @IBOutlet weak var promptButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBAction func buttonTouched(sender: AnyObject) {
        let picker = UIImagePickerController()
        picker.sourceType = .PhotoLibrary
        picker.allowsEditing = false
        picker.delegate = self
        presentViewController(picker, animated: true, completion: nil)
        
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String: AnyObject]) {
        dismissViewControllerAnimated(true, completion: nil)
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            // The user picked an image. Send it to Clarifai for recognition.
            imageView.image = image
            tagsLabel.text = "Recognizing..."
            promptButton.hidden = true
            recognizeImage(image)
        }
    }

    private func recognizeImage(image: UIImage!) {
        // Scale down the image. This step is optional. However, sending large images over the
        // network is slow and does not significantly improve recognition performance.
        let size = CGSizeMake(320, 320 * image.size.height / image.size.width)
        UIGraphicsBeginImageContext(size)
        image.drawInRect(CGRectMake(0, 0, size.width, size.height))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        // Encode as a JPEG.
        let jpeg = UIImageJPEGRepresentation(scaledImage, 0.9)!
        
        // Send the JPEG to Clarifai for standard image tagging.
        client.recognizeJpegs([jpeg]) {
            (results: [ClarifaiResult]?, error: NSError?) in
            if error != nil {
                print("Error: \(error)\n")
                self.tagsLabel.text = "Sorry, there was an error recognizing your image."
            } else {
                self.tagsLabel.text = "Tags:\n" + results![0].tags.joinWithSeparator(", ")
            }
            self.promptButton.enabled = true
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

}
