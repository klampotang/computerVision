//
//  ImageViewController.swift
//  ComputerVisionPortion
//
//  Created by Kelly Lampotang on 7/19/16.
//  Copyright © 2016 Kelly Lampotang. All rights reserved.
//

import UIKit
import Parse
import ParseUI


class ImageViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource {
    
    private lazy var client : ClarifaiClient = ClarifaiClient(appID: clarifaiClientID, appSecret: clarifaiClientSecret)

    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var tagsLabel: UILabel!
    @IBOutlet weak var promptButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var cards: [PFObject]?
    var resultTuple = [(Int, Double, UIImage)]()
    var chosenPicResults : [String]?
    var scores = [Double]()
    var plsImage:UIImage?
    var plsFile:PFFile?
    var plsImage2:UIImage?
    var plsFile2:PFFile?
    var pictureIndexes = [Int]()

    @IBAction func buttonTouched(sender: AnyObject) {
        let picker = UIImagePickerController()
        picker.sourceType = .PhotoLibrary
        picker.allowsEditing = false
        picker.delegate = self
        presentViewController(picker, animated: true, completion: nil)
        
    }
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return pictureIndexes.count ?? 0
    }
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("CollViewCell", forIndexPath: indexPath) as! CollCell
        
        cell.imageViewCollView.image = (resultTuple[pictureIndexes[indexPath.row]]).2
        //cell.scoreCollCell.text = (resultTuple[pictureIndexes[indexPath.row]]).1
        return cell
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
                self.chosenPicResults = results![0].tags
            }
            self.promptButton.enabled = true
            self.loadSimilarCards()
        }
    }
    private func recognizeOthers(img: UIImage!, index: Int)
    {
        //var returnArr : [String]?
        let size = CGSizeMake(320, 320 * img.size.height / img.size.width)
        UIGraphicsBeginImageContext(size)
        img.drawInRect(CGRectMake(0, 0, size.width, size.height))
        let scaledimg = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        // Encode as a JPEG.
        let jpeg = UIImageJPEGRepresentation(scaledimg, 0.9)!
        
        // Send the JPEG to Clarifai for standard image tagging.
        client.recognizeJpegs([jpeg])  {
            (results: [ClarifaiResult]?, error: NSError?) in
            if error != nil {
                print("Error: \(error)\n")
                self.tagsLabel.text = "Sorry, there was an error recognizing other image."
            } else {
                let returnArrOthers = results![0].tags
                let score = self.calculateScore(self.chosenPicResults!, tagsOther: returnArrOthers, index: index)
                (self.resultTuple[index]).1 = score
                self.returnTop5()

            }
        }
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.dataSource = self
        collectionView.delegate = self 
        
    }
    func loadSimilarCards()
    {
        print("beginning")
        //Get all the cards from the database
        let query = PFQuery(className: "Card")
        query.findObjectsInBackgroundWithBlock { (cards: [PFObject]?, error: NSError?) in
            if cards == nil
            {
                print("Error \(error)")
            }
            else
            {
                self.cards = cards
                var gotPictures = [UIImage]()
                for (index,card) in self.cards!.enumerate()
                {
                //Send each card to the algorithm
                    let imageFile = card["media"] as! PFFile
                    self.plsFile = imageFile
                    self.getDataFromPFFile(imageFile, index: index)
                }
            }
        }
        
    }
    func getDataFromPFFile(file: PFFile, index: Int) {
        
        file.getDataInBackgroundWithBlock({
            (imageData: NSData?, error: NSError?) -> Void in
            if (error == nil) {
                let dataImage = UIImage(data:imageData!)
                self.plsImage = dataImage
                self.resultTuple.append((index, 0, dataImage!)) //FIX
                self.recognizeOthers(self.plsImage, index: index) //Returns an array of tags for the "other"
            }
        })

    }
    func calculateScore(tags: [String], tagsOther: [String], index: Int) -> Double
    {
        var count = 0
        for tag in tags
        {
            for tagOther in tagsOther
            {
                if tag == tagOther
                {
                    count += 1
                }
            }
        }
        return (Double(count) / 20)
    }
    func returnTop5()
    {

        let sortedArr = resultTuple.sort({ $0.1 > $1.1 })
        //Get top 5
        if(sortedArr.count >= 27)
        {
            var indexArray = [Int]()
            for(var i = 0; i < 5; i += 1)
            {
                print(sortedArr[i])
                indexArray.append((sortedArr[i]).0)
                
            }
            print("IndexArr: \(indexArray)")
            self.pictureIndexes = indexArray
            self.collectionView.reloadData()
            
        }
    }
    
}
