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
    
  
    var person: Person
    var rightBody: BodySide
    var leftBody: BodySide
    
    init(result: Result) {
        
        let dots = result.dots
        self.person = [BodyPart: CGPoint]()
        
        for (index, part) in BodyPart.allCases.enumerated() {
            person[part] = dots[index]
        }
        
        self.rightBody = BodySide(wrist: BodyPart.RIGHT_WRIST, elbow: BodyPart.RIGHT_ELBOW, shoulder: BodyPart.RIGHT_SHOULDER, hip: BodyPart.RIGHT_HIP, knee: BodyPart.RIGHT_KNEE, ankle: BodyPart.RIGHT_ANKLE)
        self.leftBody = BodySide(wrist: BodyPart.LEFT_WRIST, elbow: BodyPart.LEFT_ELBOW, shoulder: BodyPart.LEFT_SHOULDER, hip: BodyPart.LEFT_HIP, knee: BodyPart.LEFT_KNEE, ankle: BodyPart.LEFT_ANKLE)
    }
    
    func identifyPose() -> String {
        
        return identifyArmPosition()
    }
    
    func identifyBodyPosition() -> String {
        if isArabesque() {
            return "arabesque"
        }
        return "Free movement"
    }

    func identifyArmPosition() -> String {
        if isArmsSecondPos() {
            return "second"
        } else if isArmsBrasBasPos() {
          return "bras bas"
        } else if isArmsFirstPos() {
            return "first"
        } else if isArmsFifthPos() {
            return "fifth"
        } else if isArmsThirdPos() {
            return "third"
        } else if isArmsFourthPos() {
            return "fourth"
        } else if isArmsFourthCrossedPos() {
            return "fourth crossed"
        }
        
        return "Free movement"
    }

    func identifyLegPosition() -> String {
        if isLegsFifthPos() {
            return "fifth"
        }
        if isLegsFirstPos(){
            return "first"
        }
        if isLegsSecondPos(){
            return "second"
        }
        return "Free movement"
    }
    
    //TODO: Increase accuracy
    func isArabesque() -> Bool {
        
        if isLegStanding(side: Side.RIGHT) {
            //check that other leg is out to the side in a straight line
            print("standing on right leg")
            if isLegStraight(side: Side.LEFT){
                //check that leg is near 90deg
                print("leg is straight")
                
                let slope: CGFloat = (person[leftBody.hip]!.y - person[leftBody.ankle]!.y)/(person[leftBody.hip]!.x - person[leftBody.ankle]!.x)
                print("slope: ", slope)
                
                if abs(slope) < 0.5 {
                    return true
                }
            }
        }
        else if isLegStanding(side: Side.LEFT) {
            //check that other leg is out to the side in a straight line
            if isLegStraight(side: Side.RIGHT){
                //check that leg is near 90deg
                print("leg is straight")
                
                let slope: CGFloat = (person[rightBody.hip]!.y - person[rightBody.ankle]!.y)/(person[rightBody.hip]!.x - person[rightBody.ankle]!.x)
                print("slope: ", slope)
                
                if abs(slope) < 0.5 {
                    return true
                }
            }
        }
        return false
    }
    
    func isLegStraight(side: Side) -> Bool {
        let body: BodySide = (side == Side.RIGHT ? rightBody : leftBody)
        
        let slope1: CGFloat = (person[body.hip]!.y - person[body.knee]!.y)/(person[body.hip]!.x - person[body.knee]!.x)
        let slope2: CGFloat = (person[body.knee]!.y - person[body.ankle]!.y)/(person[body.knee]!.x - person[body.ankle]!.x)
        
        //compare slopes
        if abs(slope1 - slope2) < 1 {
            return true
        }
        
        return false
    }
    
    func isLegsFirstPos() -> Bool {
        return isLegStanding(side: Side.LEFT) && isLegStanding(side: Side.RIGHT) && (getSeparation(isX: true, part1: self.rightBody.ankle, part2: self.leftBody.ankle) < 30) && getSeparation(isX: true, part1: self.rightBody.knee, part2: self.leftBody.knee) < 40
    }
    
    func isLegsSecondPos() -> Bool {
        return isLegStanding(side: Side.LEFT) && isLegStanding(side: Side.RIGHT) && person[rightBody.ankle]!.x > person[rightBody.hip]!.x && person[leftBody.ankle]!.x < person[leftBody.hip]!.x
    }
    
    func isLegsFifthPos() -> Bool {
        print("ankle separation: ", getSeparation(isX: true, part1: self.rightBody.ankle, part2: self.leftBody.ankle))
        print("knee separation: ", getSeparation(isX: true, part1: self.rightBody.knee, part2: self.leftBody.knee))
        return isLegStanding(side: Side.LEFT) && isLegStanding(side: Side.RIGHT) && (getSeparation(isX: true, part1: self.rightBody.ankle, part2: self.leftBody.ankle) < 11) && getSeparation(isX: true, part1: self.rightBody.knee, part2: self.leftBody.knee) < 25
    }
        
    func isLegStanding(side: Side) -> Bool {
        let body: BodySide = (side == Side.RIGHT ? rightBody : leftBody)
        
        if person[body.hip]!.y < person[body.knee]!.y && person[body.knee]!.y < person[body.ankle]!.y {
            if abs(person[body.hip]!.x - person[body.knee]!.x) < 40 && abs(person[body.knee]!.x -  person[body.ankle]!.x) < 40 { //verify what good values for this would be
                return true;
            }
        }
        return false
    }
    
    func getSeparation(isX: Bool, part1: BodyPart, part2: BodyPart) -> CGFloat {
//        print(part1, " - ", part2, "separation: ", abs(person[rAnkle]!.x - person[lAnkle]!.x))
        return abs(person[part1]!.x - person[part2]!.x)
    }
    
    func isArmsBrasBasPos() -> Bool {
        
        return isArmBrasBas(side: Side.RIGHT) && isArmBrasBas(side: Side.LEFT)
    }
    
    func isArmBrasBas(side: Side) -> Bool {
        let body: BodySide = (side == Side.RIGHT ? rightBody : leftBody)

        if person[body.wrist]!.y > person[body.elbow]!.y && person[body.elbow]!.y > person[body.shoulder]!.y{
            print("bras bas slope: ", (person[body.wrist]!.y - person[body.elbow]!.y)/(person[body.wrist]!.x - person[body.elbow]!.x))
            if abs((person[body.wrist]!.y - person[body.elbow]!.y)/(person[body.wrist]!.x - person[body.elbow]!.x)) > 1 {
                return true
            }
        }
        return false
    }
    
    func isArmsFirstPos() -> Bool {
        return isArmFirst(side: Side.LEFT) && isArmFirst(side: Side.RIGHT)
    }

    func isArmFirst(side: Side) -> Bool {

        let body: BodySide = (side == Side.RIGHT ? rightBody : leftBody)
        
        if person[body.wrist]!.y > person[body.elbow]!.y && person[body.elbow]!.y > person[body.shoulder]!.y{

            if side == Side.LEFT {
                if person[body.shoulder]!.x < person[body.elbow]!.x && person[body.wrist]!.x < person[body.elbow]!.x {
                    return true
                }
            }
            else {
                if person[body.shoulder]!.x > person[body.elbow]!.x && person[body.wrist]!.x > person[body.elbow]!.x {
                    return true
                }
            }   
        }
        return false
    }

    func isArmsFifthPos() -> Bool {
        return isArmFifth(side: Side.LEFT) && isArmFifth(side: Side.RIGHT)
    }
    
    func isArmsFourthCrossedPos() -> Bool {
        return (isArmFifth(side: Side.LEFT) && isArmFirst(side: Side.RIGHT)) || (isArmFifth(side: Side.RIGHT) && isArmFirst(side: Side.LEFT))
    }

    func isArmFifth(side: Side) -> Bool {
        let body: BodySide = (side == Side.RIGHT ? rightBody : leftBody)
        
        return person[body.wrist]!.y < person[body.elbow]!.y && person[body.elbow]!.y < person[body.shoulder]!.y
    }

    func isArmsSecondPos() -> Bool {
        return isArmSecond(side: Side.LEFT) && isArmSecond(side: Side.RIGHT)
    }

    func isArmSecond(side: Side) -> Bool {

        let body: BodySide = (side == Side.RIGHT ? rightBody : leftBody)

        if (person[body.wrist]!.x != person[body.shoulder]!.x) {
            let slope = abs((person[body.wrist]!.y - person[body.shoulder]!.y)/(person[body.wrist]!.x - person[body.shoulder]!.x))

            if abs(slope) < 0.6 {
                return true
            }
        }
        return false
    }

    func isArmsThirdPos() -> Bool {
        return isArmSecond(side: Side.LEFT) && isArmFirst(side: Side.RIGHT) || isArmSecond(side: Side.RIGHT) && isArmFirst(side: Side.LEFT)
    }

    func isArmsFourthPos() -> Bool {
        return isArmSecond(side: Side.LEFT) && isArmFifth(side: Side.RIGHT) || isArmSecond(side: Side.RIGHT) && isArmFifth(side: Side.LEFT)
    }
}

typealias Person = [BodyPart: CGPoint]

enum Side: String, CaseIterable {
    case LEFT = "left"
    case RIGHT = "right"
}

struct BodySide {
    var wrist: BodyPart
    var elbow: BodyPart
    var shoulder: BodyPart
    var hip: BodyPart
    var knee: BodyPart
    var ankle: BodyPart
}
