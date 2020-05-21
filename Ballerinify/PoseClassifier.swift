//
//  PoseClassifier.swift
//  Ballerinify
//
//  Created by Kara Dietz on 2020-05-16.
//  Copyright © 2020 Angela Dietz. All rights reserved.
//

import Foundation
import UIKit

class PoseClassifier: NSObject {

    func identifyPose(result: Result) -> String {
        let dots = result.dots
        var person = [BodyPart: CGPoint]()
        
        for (index, part) in BodyPart.allCases.enumerated() {
            person[part] = dots[index]
        }
        
        if person[BodyPart.LEFT_WRIST]!.y > person[BodyPart.LEFT_ELBOW]!.y {
            if person[BodyPart.LEFT_ELBOW]!.y > person[BodyPart.LEFT_SHOULDER]!.y {
                if person[BodyPart.RIGHT_WRIST]!.y > person[BodyPart.RIGHT_ELBOW]!.y {
                    if person[BodyPart.RIGHT_ELBOW]!.y > person[BodyPart.RIGHT_SHOULDER]!.y {
                        return "first"
                    }
                }
            }
        }
        
        else if person[BodyPart.LEFT_WRIST]!.y < person[BodyPart.LEFT_ELBOW]!.y && person[BodyPart.LEFT_ELBOW]!.y < person[BodyPart.LEFT_SHOULDER]!.y {
                if person[BodyPart.RIGHT_WRIST]!.y < person[BodyPart.RIGHT_ELBOW]!.y && person[BodyPart.RIGHT_ELBOW]!.y < person[BodyPart.RIGHT_SHOULDER]!.y {
                    return "fifth"
            }
        }
        //second position
        //check slope of line
        else {
            if (person[BodyPart.LEFT_WRIST]!.x != person[BodyPart.LEFT_SHOULDER]!.x) &&  (person[BodyPart.RIGHT_WRIST]!.x != person[BodyPart.RIGHT_SHOULDER]!.x) {
                let leftSlope = abs((person[BodyPart.LEFT_WRIST]!.y - person[BodyPart.LEFT_SHOULDER]!.y)/(person[BodyPart.LEFT_WRIST]!.x - person[BodyPart.LEFT_SHOULDER]!.x))

                let rightSlope = abs((person[BodyPart.RIGHT_WRIST]!.y - person[BodyPart.RIGHT_SHOULDER]!.y)/(person[BodyPart.RIGHT_WRIST]!.x - person[BodyPart.RIGHT_SHOULDER]!.x))

                if leftSlope < 0.5 && leftSlope > 0.3 && rightSlope < 0.5 && rightSlope > 0.3{
                    return "second"
                }
            }
        }
        
        return "Not Ballet"
    }
}
