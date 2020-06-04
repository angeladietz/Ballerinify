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

    func identifyPose(result: Result) -> String {
        let dots = result.dots
        var person: Person = [BodyPart: CGPoint]()
        
        for (index, part) in BodyPart.allCases.enumerated() {
            person[part] = dots[index]
        }
        
        return identifyArmPosition(person: person)
    }

    func identifyArmPosition(person: Person) -> String {
        if isArmsSecondPos(person: person) {
            return "second"
        }
        else if isArmsFirstPos(person: person) {
            return "first"
        }
        else if isArmsFifthPos(person: person) {
            return "fifth"
        }
        else if isArmsThirdPos(person: person) {
            return "third"
        }
        else if isArmsFourthPos(person: person) {
            return "fourth"
        }
        return "Not ballet"
    }

    func isArmsFirstPos(person: Person) -> Bool {
        if isArmFirst(person: person, side: Side.LEFT) && isArmFirst(person: person, side: Side.RIGHT) {
            return true
        }
        return false
    }

    func isArmFirst(person: Person, side: Side) -> Bool {
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

        if person[wrist]!.y > person[elbow]!.y && person[elbow]!.y > person[shoulder]!.y{
            if side == Side.LEFT {
                if person[shoulder]!.x > person[elbow]!.x && person[wrist]!.x > person[elbow]!.x {
                    return true
                }
            }
            else {
                if person[shoulder]!.x < person[elbow]!.x && person[wrist]!.x < person[elbow]!.x {
                    return true
                }
            }   
        }
        return false
    }

    func isArmsFifthPos(person: Person) -> Bool {
        if isArmFifth(person: person, side: Side.LEFT) && isArmFifth(person: person, side: Side.RIGHT) {
            return true
        }
        return false
    }

    func isArmFifth(person: Person, side: Side) -> Bool {
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

    func isArmsSecondPos(person: Person) -> Bool {
        if isArmSecond(person: person, side: Side.LEFT) && isArmSecond(person: person, side: Side.RIGHT) {
            return true
        }
        return false
    }

    func isArmSecond(person: Person, side: Side) -> Bool {
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

            if abs(slope) < 0.5 {
                return true
            }
        }
        return false
    }

    func isArmsThirdPos(person: Person) -> Bool {
        if isArmSecond(person: person, side: Side.LEFT) && isArmFirst(person: person, side: Side.RIGHT) || isArmSecond(person: person, side: Side.RIGHT) && isArmFirst(person: person, side: Side.LEFT) {
            return true
        }
        return false
    }

    func isArmsFourthPos(person: Person) -> Bool {
        if isArmSecond(person: person, side: Side.LEFT) && isArmFifth(person: person, side: Side.RIGHT) || isArmSecond(person: person, side: Side.RIGHT) && isArmFifth(person: person, side: Side.LEFT) {
            return true
        }
        return false
    }
}

typealias Person = [BodyPart: CGPoint]

enum Side: String, CaseIterable {
    case LEFT = "left"
    case RIGHT = "right"
}
