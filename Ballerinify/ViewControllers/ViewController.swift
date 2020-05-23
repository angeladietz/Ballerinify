
//
//  ViewController.swift
//  Ballerinify
//
//  Created by Angela Dietz on 2020-05-06.
//  Copyright © 2020 Angela Dietz. All rights reserved.
//
// Copyright 2019 The TensorFlow Authors. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
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
    var threadCount: Int = Constants.defaultThreadCount
//  var delegate: Delegates = Constants.defaultDelegate
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

  // Handles all data preprocessing and makes calls to run inference.
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
//    tableView.delegate = self
//    tableView.dataSource = self
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
//    self.resumeButton.isHidden = false
  }

  func cameraFeedManager(
    _ manager: CameraFeedManager, sessionWasInterrupted canResumeManually: Bool
  ) {
    // Updates the UI when session is interupted.
    if canResumeManually {
//      self.resumeButton.isHidden = false
    } else {
      self.feedUnavailableLabel.isHidden = false
    }
  }

  func cameraFeedManagerDidEndSessionInterruption(_ manager: CameraFeedManager) {
    // Updates UI once session interruption has ended.
    self.feedUnavailableLabel.isHidden = true
//    self.resumeButton.isHidden = true
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
    guard let modelViewFrame = modelViewFrame, let previewViewFrame = previewViewFrame
    else {
      return
    }
    // To put `modelView` area as model input, transform `modelViewFrame` following transform
    // from `previewView` to `pixelBuffer`. `previewView` area is transformed to fit in
    // `pixelBuffer`, because `pixelBuffer` as a camera output is resized to fill `previewView`.
    // https://developer.apple.com/documentation/avfoundation/avlayervideogravity/1385607-resizeaspectfill
    let modelInputRange = modelViewFrame.applying(
      modelViewFrame.size.transformKeepAspect(toFitIn: pixelBuffer.size))

//    let viewFrameSize = CGSize(width: 375, height: 375)
    
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

    // Udpate `inferencedData` to render data in `tableView`.
    inferencedData = InferencedData(score: result.score, times: times)

    
    
    // Determine result.
    DispatchQueue.main.async {

        if result.score < self.minimumScore {
            print("Confidence score is too low.")
            return
        }

        //logic: there are two labels: one for arms, one for legs. if we detect a full body pose (arabesque) use arm label and hide leg label. leg label is hidden by default, so unhide it when a leg position is found

        let pose = self.poseClassifier?.identifyPose(result: result)
        self.ArmsPositionLabel.text = "Arm Position: " + pose!

        // TODO: Draw result here (skeleton) if that's a feature that will be implemented)
    }
  }
}

//extension ViewController : UIViewControllerRepresentable{
//    public typealias UIViewControllerType = ViewController
//
//    public func makeUIViewController(context: UIViewControllerRepresentableContext<ViewController>) -> ViewController {
//        return ViewController()
//    }
//
//    public func updateUIViewController(_ uiViewController: ViewController, context: UIViewControllerRepresentableContext<ViewController>) {
//    }
//}
// MARK: - TableViewDelegate, TableViewDataSource Methods
//extension ViewController: UITableViewDelegate {
//  func numberOfSections(in tableView: UITableView) -> Int {
//    return InferenceSections.allCases.count
//  }
//
//  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//    guard let section = InferenceSections(rawValue: section) else {
//      return 0
//    }
//
//    return section.subcaseCount
//  }
//  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//    let cell = tableView.dequeueReusableCell(withIdentifier: "InfoCell") as! InfoCell
//    guard let section = InferenceSections(rawValue: indexPath.section) else {
//      return cell
//    }
//    guard let data = inferencedData else { return cell }
//
//    var fieldName: String
//    var info: String
//
//    switch section {
//    case .Score:
//      fieldName = section.description
//      info = String(format: "%.3f", data.score)
//    case .Time:
//      guard let row = ProcessingTimes(rawValue: indexPath.row) else {
//        return cell
//      }
//      var time: Double
//      switch row {
//      case .InferenceTime:
//        time = data.times.inference
//      }
//      fieldName = row.description
//      info = String(format: "%.2fms", time)
//    }
//
//    cell.fieldNameLabel.text = fieldName
//    cell.infoLabel.text = info
//
//    return cell
//  }
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    guard let section = InferenceSections(rawValue: indexPath.section) else {
      return 0
    }

    var height = Traits.normalCellHeight
    if indexPath.row == section.subcaseCount - 1 {
      height = Traits.separatorCellHeight + Traits.bottomSpacing
    }
    return height
  }

// MARK: - Private enums
/// UI coinstraint values
fileprivate enum Traits {
  static let normalCellHeight: CGFloat = 35.0
  static let separatorCellHeight: CGFloat = 25.0
  static let bottomSpacing: CGFloat = 30.0
}

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
