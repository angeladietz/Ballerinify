
//
//  ViewController.swift
//  Ballerinify
//
//  Created by Angela Dietz and Kara Dietz on 2020-05-06.
//  Copyright © 2020 Angela Dietz and Kara Dietz. All rights reserved.

import Accelerate
import CoreImage
import Foundation
import TensorFlowLite
import UIKit
import os

final class ViewController: UIViewController {

    // MARK: Storyboards Connections
    @IBOutlet weak var previewView: PreviewView!
    @IBOutlet weak var modelView: ModelView!
    
    // MARK: ModelDataHandler traits
    @IBOutlet weak var feedUnavailableLabel: UILabel!
    
    // MARK: Result Variables
    // Inferenced data to render.
    private var inferencedData: InferencedData?
    @IBOutlet weak var PositionNameTextbox: UILabel!
    @IBOutlet weak var ArmsPositionLabel: UILabel!
    @IBOutlet weak var LegsPositionLabel: UILabel!
    
    // Minimum score to render the result.
    private let minimumScore: Float = 0.5

    // Relative location of `movelView` to `previewView`.
    private var modelViewFrame: CGRect?
    private var previewViewFrame: CGRect?

    // MARK: Controllers that manage functionality
    private var usingFrontCamera: Bool = false
    private lazy var cameraCapture = CameraFeedManager(previewView: previewView, usingFrontCamera: usingFrontCamera)

    // Handles all data preprocessing and makes calls to run inference (classify positions).
    private var modelDataHandler: ModelDataHandler?

    @IBOutlet var tapRecognizer: UITapGestureRecognizer!
    
    // TODO: resolve issue with camera feed dimensions
    @IBAction func tapGestureRecognizer(_ sender: UITapGestureRecognizer) {
        
        guard sender.view != nil else { return }
        if sender.state == .ended {
//            usingFrontCamera = !usingFrontCamera
//            cameraCapture.usingFrontCamera = usingFrontCamera
//            cameraCapture.changeCamera()
        }
    }
    

    // MARK: View Handling Methods
    override func viewDidLoad() {
        super.viewDidLoad()

        do {
            modelDataHandler = try ModelDataHandler()
        } catch let error {
            fatalError(error.localizedDescription)
        }

        cameraCapture.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        cameraCapture.checkCameraConfigurationAndStartSession()
    }

    override func viewWillDisappear(_ animated: Bool) {
        cameraCapture.stopSession()
    }

    override func viewDidLayoutSubviews() {
        modelViewFrame = modelView.frame
        previewViewFrame = previewView.frame
    }

    func presentUnableToResumeSessionAlert() {
        let alert = UIAlertController(
            title: "Unable to Resume Session",
            message: "There was an error while attempting to resume session.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))

        self.present(alert, animated: true)
    }
}

// MARK: - CameraFeedManagerDelegate Methods
extension ViewController: CameraFeedManagerDelegate {
    func cameraFeedManager(_ manager: CameraFeedManager, didOutput pixelBuffer: CVPixelBuffer) {
        runModel(on: pixelBuffer)
    }

    // MARK: Session Handling Alerts
    func cameraFeedManagerDidEncounterSessionRunTimeError(_ manager: CameraFeedManager) {
        // Handles session run time error by updating the UI and providing a button if session can be
        // manually resumed.
        // TODO: add error handling?
    }

    func cameraFeedManager(
        _ manager: CameraFeedManager, sessionWasInterrupted canResumeManually: Bool
    ) {
        // Updates the UI when session is interupted.
        self.feedUnavailableLabel.isHidden = false
    }

    func cameraFeedManagerDidEndSessionInterruption(_ manager: CameraFeedManager) {
        // Updates UI once session interruption has ended.
        self.feedUnavailableLabel.isHidden = true
      }

    func presentVideoConfigurationErrorAlert(_ manager: CameraFeedManager) {
        let alertController = UIAlertController(
            title: "Configuration Failed", message: "Configuration of camera has failed.",
            preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }

    func presentCameraPermissionsDeniedAlert(_ manager: CameraFeedManager) {
        let alertController = UIAlertController(
            title: "Camera Permissions Denied",
            message:
            "Camera permissions have been denied for this app. You can change this by going to Settings",
            preferredStyle: .alert)

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let settingsAction = UIAlertAction(title: "Settings", style: .default) { action in
            if let url = URL.init(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }

        alertController.addAction(cancelAction)
        alertController.addAction(settingsAction)

        present(alertController, animated: true, completion: nil)
    }

    @objc func runModel(on pixelBuffer: CVPixelBuffer) {
        
        guard let modelViewFrame = modelViewFrame else {
            return
        }

        // Set bounds for model
        let modelInputRange = modelViewFrame.applying(
            modelViewFrame.size.transformKeepAspect(toFitIn: pixelBuffer.size))
        
        
//        let rect = CGRect(x: 0.0, y: 420.0, width: 1080.0, height: 1080.0)
//        if !(rect.equalTo(modelInputRange)){
//            print("not equal, setting one to the other")
//            modelInputRange = rect
//        }
                
        // Run PoseNet model.
        guard
            let (result, times) = self.modelDataHandler?.runPoseNet(
                on: pixelBuffer,
                from: modelInputRange,
                to: modelViewFrame.size)
            else {
                os_log("Cannot get inference result.", type: .error)
                return
        }

        // Udpate `inferencedData` to render data.
        inferencedData = InferencedData(score: result.score, times: times)
    
        // Determine result.
        DispatchQueue.main.async {
            
            if result.score < self.minimumScore {
                self.ArmsPositionLabel.text = "calculating position"
                self.LegsPositionLabel.isHidden = true
                print("Confidence score is too low.")
                return
            }
            
            let poseClassifier: PoseClassifier? = PoseClassifier(result: result)
            let bodyPose = poseClassifier!.identifyBodyPosition()
            let armPose = poseClassifier!.identifyArmPosition()
            let legPose = poseClassifier!.identifyLegPosition()

            if bodyPose != "Free movement" {
                self.LegsPositionLabel.isHidden = true
                self.ArmsPositionLabel.text = "Position: " + bodyPose
            } else if armPose == "Free movement" && legPose == "Free movement" {
                self.LegsPositionLabel.isHidden = true
                self.ArmsPositionLabel.text = "Position: " + armPose
            } else if legPose == "Free movement" {
                self.LegsPositionLabel.isHidden = true
                self.ArmsPositionLabel.text = "Arm Position: " + armPose
            } else if armPose == "Free movement" {
                self.ArmsPositionLabel.text = "    "
                self.LegsPositionLabel.isHidden = false
                self.LegsPositionLabel.text = "Leg Position: " + legPose
            } else {
                // arm is free movement and legs has set position
                // both have positions available
                self.LegsPositionLabel.isHidden = false
                self.ArmsPositionLabel.text = "Arm Position: " + armPose
                self.LegsPositionLabel.text = "Leg Position: " + legPose
            }
            
            // TODO: Draw result here (skeleton) if that's a feature that will be implemented)
    }
  }
}

// MARK: - Private enums
fileprivate struct InferencedData {
    var score: Float
    var times: Times
}

/// Type of sections in Info Cell
fileprivate enum InferenceSections: Int, CaseIterable {
    case Score
    case Time

    var description: String {
        switch self {
        case .Score:
            return "Score"
        case .Time:
            return "Processing Time"
        }
    }

    var subcaseCount: Int {
        switch self {
        case .Score:
            return 1
        case .Time:
            return ProcessingTimes.allCases.count
        }
    }
}

/// Type of processing times in Time section in Info Cell
fileprivate enum ProcessingTimes: Int, CaseIterable {
    case InferenceTime

    var description: String {
        switch self {
        case .InferenceTime:
          return "Inference Time"
        }
    }
}
