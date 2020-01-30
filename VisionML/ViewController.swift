//
//  ViewController.swift
//  VisionML
//
//  Created by Brian Advent on 27.09.17.
//  Copyright © 2017 Brian Advent. All rights reserved.
//

import UIKit
import AVFoundation
import Vision

class ViewController: UIViewController {
    
    @IBOutlet weak var previewView: PreviewView!
    @IBOutlet weak var objectTextView: UITextView!
    
    
    // Live Camera Properties
    let captureSession = AVCaptureSession()
    var captureDevice:AVCaptureDevice!
    var devicePosition: AVCaptureDevice.Position = .back
    
    var requests = [VNRequest]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupVision()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        prepareCamera()
    }
    
    func setupVision() {
        let rectangleDetectionRequest = VNDetectRectanglesRequest(completionHandler: handleRectangles)
        rectangleDetectionRequest.minimumSize = 0.1
        rectangleDetectionRequest.maximumObservations = 1
        
        // Object Classification
        guard let visionModel = try? VNCoreMLModel(for: Inceptionv3().model) else {fatalError("cant load Inception model")}
        
        let classificationRequest = VNCoreMLRequest(model: visionModel, completionHandler: handleClassification)
        
        classificationRequest.imageCropAndScaleOption = .centerCrop
        
        self.requests = [rectangleDetectionRequest, classificationRequest]
        
    
    }
    
    func handleRectangles (request:VNRequest, error:Error?) {
        DispatchQueue.main.async {
            self.drawVisionRequestResults(results: request.results as! [VNRectangleObservation])
        }
    }
    
    func drawVisionRequestResults ( results:[VNRectangleObservation]) {
        previewView.removeMask()
        
        let transform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -self.previewView.frame.height)
        let translate = CGAffineTransform.identity.scaledBy(x: self.previewView.frame.width, y: self.previewView.frame.height)
        
        for rectangle in results {
            let rectangleBounds = rectangle.boundingBox.applying(translate).applying(transform)
            previewView.drawLayer(in: rectangleBounds)
        }
    }
    
    func handleClassification (request: VNRequest, error: Error?) {
        guard let observations = request.results else {print("no results: \(error?.localizedDescription)"); return}
        
        let classifications = observations[0...4]
            .flatMap({$0 as? VNClassificationObservation})
            .filter({$0.confidence > 0.3})
            .map({$0.identifier})
        
        for classification in classifications {
            DispatchQueue.main.async { self.objectTextView.text=classification
            }
        }
    }
}
