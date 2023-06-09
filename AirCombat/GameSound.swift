//
//  GameSound.swift
//
//  Created by 董震宇 on 2020/12/7.
//

import Foundation
import SceneKit
import AudioToolbox.AudioServices

class GameSound {
    private static let explosion = SCNAudioSource(fileNamed: "sounds/explosion.wav")
    private static let fire = SCNAudioSource(fileNamed: "sounds/fire.wav")
    private static let bonus = SCNAudioSource(fileNamed: "sounds/bonus.wav")

    // -------------------------------------------------------------------------
    // MARK: - Vibrate
    
    static func vibrate() {
        Debug("GameSound: vibrate")
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }

    // -------------------------------------------------------------------------

    private static func play(_ name: String, source: SCNAudioSource, node: SCNNode) {
        let _ = GameAudioPlayer(name: name, source: source, node: node)
    }
    
    // -------------------------------------------------------------------------
    // MARK: - Sound effects
    
    static func explosion(_ node: SCNNode) {
        guard explosion != nil else { return }
        
        GameSound.play("explosion", source: GameSound.explosion!, node: node)
        GameSound.vibrate()
    }
    
    // -------------------------------------------------------------------------
    
    static func fire(_ node: SCNNode) {
        guard fire != nil else { return }
        
        GameSound.play("fire", source: GameSound.fire!, node: node)
        GameSound.vibrate()
    }
    
    // -------------------------------------------------------------------------
    
    static func bonus(_ node: SCNNode) {
        guard bonus != nil else { return }
        
        GameSound.play("bonus", source: GameSound.bonus!, node: node)
    }

    // -------------------------------------------------------------------------
    
}

class GameAudioPlayer : SCNAudioPlayer {
    private var _node: SCNNode!
    
    init(name: String, source: SCNAudioSource, node: SCNNode) {
        super.init(source: source)
        
        node.addAudioPlayer(self)
        _node = node

        Debug("GameAudioPlayer: play \(name)")

        self.didFinishPlayback = {
            Debug("GameAudioPlayer: stopped \(name)")

            self._node.removeAudioPlayer(self)
        }
    }
    
}

