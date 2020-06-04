//
//  PoseClassifier.swift
//  Ballerinify
//
//  Created by Kara Dietz and Angela Dietz on 2020-05-16.
//  Copyright © 2020 Kara Dietz and Angela Dietz. All rights reserved.
//

import Foundation
import UIKit

class PoseClassifier: NSObject {
    
    var rWrist: BodyPart
    var lWrist: BodyPart
    var lElbow: BodyPart
    var rElbow: BodyPart
    var lShoulder: BodyPart
    var rShoulder: BodyPart
    var lHip: BodyPart
    var rHip: BodyPart
    var lKnee: BodyPart
    var rKnee: BodyPart
    var lAnkle: BodyPart
    var rAnkle: BodyPart
    
    var person: Person
    
    init(result: Result) {
        
        let dots = result.dots
        self.person = [BodyPart: CGPoint]()
        
        for (index, part) in BodyPart.allCases.enumerated() {
            person[part] = dots[index]
        }
        
        self.rWrist = BodyPart.RIGHT_WRIST
        self.lWrist = BodyPart.LEFT_WRIST
        self.lElbow = BodyPart.LEFT_ELBOW
        self.rElbow = BodyPart.RIGHT_ELBOW
        self.lShoulder = BodyPart.LEFT_SHOULDER
        self.rShoulder = BodyPart.RIGHT_SHOULDER
        self.lHip = BodyPart.LEFT_HIP
        self.rHip = BodyPart.RIGHT_HIP
        self.lKnee = BodyPart.LEFT_KNEE
        self.rKnee = BodyPart.RIGHT_KNEE
        self.lAnkle = BodyPart.LEFT_ANKLE
        self.rAnkle = BodyPart.RIGHT_ANKLE
        
    }

//    func identifyPose(result: Result) -> String {
////        let dots = result.dots
////        var person: Person = [BodyPart: CGPoint]()
////
////        for (index, part) in BodyPart.allCases.enumerated() {
////            person[part] = dots[index]
////        }
//        return identifyArmPosition()
//    }
    
    func identifyPose() -> String {
        
        return identifyArmPosition()
    }

    func identifyArmPosition() -> String {
        if isArmsSecondPos() {
            return "second"
        }
        else if isArmsFirstPos() {
            return "first"
        }
        else if isArmsFifthPos() {
            return "fifth"
        }
        return "Free movement"
    }

    func identifyLegPosition() -> String {
        if isLegsFirst(){
            return "first"
        }
        if isLegsSecond(){
            return "second"
        }
        return "Free movement"
    }
    
    
    func isLegsFirst() -> Bool {
        if isLegStanding(side: Side.LEFT) && isLegStanding(side: Side.RIGHT) && (getAnkleSeparation() < 5) {
            return true
        }
        
        return false
    }
    
    func isLegsSecond() -> Bool {
        if isLegStanding(side: Side.LEFT) && isLegStanding(side: Side.RIGHT) && getAnkleSeparation() > 10 && getAnkleSeparation() < 40 {
            return true
        }
        
        return false
    }
        
    func isLegStanding(side: Side) -> Bool {
        var hip: BodyPart
        var knee: BodyPart
        var ankle: BodyPart
        
        if (side == Side.LEFT){
            hip = lHip
            knee = lKnee
            ankle = lAnkle
        } else {
            hip = rHip
            knee = rKnee
            ankle = rAnkle
        }
        
        if person[hip]!.y > person[knee]!.y && person[knee]!.y > person[ankle]!.y {
            if person[hip]!.x - person[knee]!.x < 40 && person[knee]!.x -  person[ankle]!.x < 40 { //check what good numbers for this would be
                return true;
            }
        }
        return false
    }
    
    func getAnkleSeparation() -> CGFloat {
        return (person[rAnkle]!.x - person[lAnkle]!.x)
    }
    
    func isArmsFirstPos() -> Bool {
        if isArmFirst(side: Side.LEFT) && isArmFirst(side: Side.RIGHT) {
            return true
        }
        return false
    }

    func isArmFirst(side: Side) -> Bool {
        var wrist: BodyPart
        var elbow: BodyPart
        var shoulder: BodyPart

        if side == Side.LEFT{
            wrist = lWrist
            elbow = lElbow
            shoulder = lShoulder
        }
        else {
            wrist = rWrist
            elbow = rElbow
            shoulder = rShoulder
        }

        if person[wrist]!.y > person[elbow]!.y {
            if person[elbow]!.y > person[shoulder]!.y {
                return true
            }
        }
        return false
    }

    func isArmsFifthPos() -> Bool {
        if isArmFifth(side: Side.LEFT) && isArmFifth(side: Side.RIGHT) {
            return true
        }
        return false
    }

    func isArmFifth(side: Side) -> Bool {
        var wrist: BodyPart
        var elbow: BodyPart
        var shoulder: BodyPart
        
        if side == Side.LEFT{
            wrist = BodyPart.LEFT_WRIST
            elbow = BodyPart.LEFT_ELBOW
            shoulder = BodyPart.LEFT_SHOULDER
        }
        else {
            wrist = BodyPart.RIGHT_WRIST
            elbow = BodyPart.RIGHT_ELBOW
            shoulder = BodyPart.RIGHT_SHOULDER
        }
        
        if person[wrist]!.y < person[elbow]!.y {
            if person[elbow]!.y < person[shoulder]!.y {
                return true
            }
        }
        return false
    }

    func isArmsSecondPos() -> Bool {
        if isArmSecond(side: Side.LEFT) && isArmSecond(side: Side.RIGHT) {
            return true
        }
        return false
    }

    func isArmSecond(side: Side) -> Bool {
        var wrist: BodyPart
        var shoulder: BodyPart

        if side == Side.LEFT{
            wrist = BodyPart.LEFT_WRIST
            shoulder = BodyPart.LEFT_SHOULDER
        }
        else {
            wrist = BodyPart.RIGHT_WRIST
            shoulder = BodyPart.RIGHT_SHOULDER
        }

        if (person[wrist]!.x != person[shoulder]!.x) {
            let slope = abs((person[wrist]!.y - person[shoulder]!.y)/(person[wrist]!.x - person[shoulder]!.x))

            if abs(slope) < 0.6 {
                return true
            }
        }
        return false
    }
    
    
}

typealias Person = [BodyPart: CGPoint]

enum Side: String, CaseIterable {
    case LEFT = "left"
    case RIGHT = "right"
}
