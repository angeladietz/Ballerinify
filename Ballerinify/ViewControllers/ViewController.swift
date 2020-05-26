
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
    // Handles all the camera related functionality
    private lazy var cameraCapture = CameraFeedManager(previewView: previewView)

    // Handles all data preprocessing and makes calls to run inference (classify positions).
    private var modelDataHandler: ModelDataHandler?
    private var poseClassifier: PoseClassifier? = PoseClassifier()

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
                print("Confidence score is too low.")
                return
            }

            let pose = self.poseClassifier?.identifyPose(result: result)
            self.ArmsPositionLabel.text = "Arm Position: " + pose!
            
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
