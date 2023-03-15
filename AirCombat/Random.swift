//
//  Random.swift
//  Random number extensions
//
//  Created by 董震宇 on 2020/12/3.
//


import Foundation
import GameKit

extension Int {
    static func random(maxValue: Int) -> Int {
        let rand = Int(arc4random_uniform(UInt32(maxValue)))
        return rand
    }
}

class Random {
    private let source = GKMersenneTwisterRandomSource()
    
    // -------------------------------------------------------------------------
    // MARK: - Get random numbers
    
    class func boolean() -> Bool {
        if Random.sharedInstance.integer(0, 1) == 1 {
            return true
        }
        
        return false
    }

    // -------------------------------------------------------------------------

    class func integer(_ from: Int, _ to: Int) -> Int {
        return Random.sharedInstance.integer(from, to)
    }

    // -------------------------------------------------------------------------
    
    class func timeInterval(_ from: Int, _ to: Int) -> TimeInterval {
        return TimeInterval(Random.sharedInstance.integer(from, to))
    }
    
    // -------------------------------------------------------------------------
    
    class func cgFloat(_ from: CGFloat, _ to: CGFloat) -> CGFloat {
        return CGFloat(Random.sharedInstance.integer(Int(from), Int(to)))
    }
    
    // -------------------------------------------------------------------------
    
    private func integer(_ from: Int, _ to: Int) -> Int {
        let rd = GKRandomDistribution(randomSource: self.source, lowestValue: from, highestValue: to)
        let number = rd.nextInt()
        
        return number
    }
    
    // -------------------------------------------------------------------------
    // MARK: - Initialisation
    
    init() {
        source.seed = UInt64(CFAbsoluteTimeGetCurrent())
    }
    
    // -------------------------------------------------------------------------
    
    private static let sharedInstance : Random = {
        let instance = Random()
        return instance
    }()
    
    // -------------------------------------------------------------------------

}

