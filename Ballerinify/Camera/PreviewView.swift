//
//  PreviewView.swift
//  Ballerinify
//
//  Created by Kara Dietz and Angela Dietz on 2020-05-06.
//  Copyright © 2020 Kara Dietz and Angela Dietz. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

 /// The camera frame is displayed on this view.
class PreviewView: UIView {
    
  var previewLayer: AVCaptureVideoPreviewLayer {
    guard let layer = layer as? AVCaptureVideoPreviewLayer else {
      fatalError("Layer expected is of type VideoPreviewLayer")
    }
    return layer
  }

  var session: AVCaptureSession? {
    get {
      return previewLayer.session
    }
    set {
      previewLayer.session = newValue
    }
  }

  override class var layerClass: AnyClass {
    return AVCaptureVideoPreviewLayer.self
  }
}
