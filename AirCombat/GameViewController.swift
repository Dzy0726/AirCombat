//
//  GameViewController.swift
//
//  Created by 董震宇 on 2020/12/1.
//

import UIKit
import SceneKit
import SpriteKit
import CoreMotion
import GameController

class GameViewController: UIViewController, SCNSceneRendererDelegate {
    private var _sceneView: SCNView!    //负责显示3D内容的SceneKit视图
    private var _level: GameLevel!
    private var _hud: HUD!

    // Use CoreMotion to fly the plane
    private var _motionManager = CMMotionManager()
    private var _startAttitude: CMAttitude?             // Start attitude
    private var _currentAttitude: CMAttitude?           // Current attitude

    // -------------------------------------------------------------------------
    // MARK: - Properties

    var sceneView: SCNView {
        return _sceneView
    }

    // -------------------------------------------------------------------------

    var hud: HUD {
        return _hud
    }

    // -------------------------------------------------------------------------
    // MARK: - Render delegate
    
    func renderer(_ renderer: SCNSceneRenderer, didSimulatePhysicsAtTime time: TimeInterval) {
        guard _level != nil else { return }

        _level.update(atTime: time)
        renderer.loops = true
    }

    // -------------------------------------------------------------------------
    // MARK: - Gesture recognoizers
    
    @objc private func handleTap(_ gestureRecognize: UITapGestureRecognizer) {
        //
        if _level.state == .loose || _level.state == .win {
            _level.stop()
            _level = nil
            
            DispatchQueue.main.async {
                // Create things in main thread
                
                let level = GameLevel()
                level.create()
                
                level.hud = self.hud
                self.hud.reset()
                
                self.sceneView.scene = level
                self._level = level

                self.hud.message("READY?", information: "- Touch screen to start -")
            }
        }
            // A tap is used to start the level
        else if _level.state == .ready {
            _startAttitude = _currentAttitude
            _level.start()
        }
        // A tap is used to shot fire
        else if _level.state == .play {
            _level.fire()
        }
    }

    // -------------------------------------------------------------------------

    @objc private func handleSwipe(_ gestureRecognize: UISwipeGestureRecognizer) {
        if _level.state != .play {
            return
        }
        
        if (gestureRecognize.direction == .left) {
            _level!.swipeLeft()
        }
        else if (gestureRecognize.direction == .right) {
            _level!.swipeRight()
        }
        else if (gestureRecognize.direction == .down) {
            _level!.swipeDown()
        }
        else if (gestureRecognize.direction == .up) {
            _level!.swipeUp()
        }
    }
    
    // -------------------------------------------------------------------------
    // MARK: - Motion handling
    
    private func motionDidChange(data: CMDeviceMotion) {
        _currentAttitude = data.attitude
        
        guard _level != nil, _level?.state == .play else { return }
        
        // Up/Down
        let diff1 = _startAttitude!.roll - _currentAttitude!.roll
        
        if (diff1 >= Game.Motion.threshold) {
            _level!.motionMoveUp()
        }
        else if (diff1 <= -Game.Motion.threshold) {
            _level!.motionMoveDown()
        }
        else {
            _level!.motionStopMovingUpDown()
        }
        
        let diff2 = _startAttitude!.pitch - _currentAttitude!.pitch
        
        if (diff2 >= Game.Motion.threshold) {
            _level!.motionMoveLeft()
        }
        else if (diff2 <= -Game.Motion.threshold) {
            _level!.motionMoveRight()
        }
        else {
            _level!.motionStopMovingLeftRight()
        }
    }

    // -------------------------------------------------------------------------

    private func setupMotionHandler() {
        if (GCController.controllers().count == 0 && _motionManager.isAccelerometerAvailable) {
            _motionManager.accelerometerUpdateInterval = 1/60.0
            
            _motionManager.startDeviceMotionUpdates(to: OperationQueue.main, withHandler: {(data, error) in
                self.motionDidChange(data: data!)
            })
        }
    }

    // -------------------------------------------------------------------------
    // MARK: - ViewController life cycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // 
        _hud = HUD(size: self.view.bounds.size)
        _level.hud = _hud
        _sceneView.overlaySKScene = _hud.scene
        
        self.hud.message("READY?", information: "- Touch screen to start -")
    }

    // -------------------------------------------------------------------------

    override func viewDidLoad() {
        super.viewDidLoad()
        
        _level = GameLevel()
        _level.create()
        
        _sceneView = SCNView()
        _sceneView.scene = _level
        _sceneView.allowsCameraControl = false
        _sceneView.showsStatistics = false
        _sceneView.backgroundColor = UIColor.black
        _sceneView.delegate = self

        self.view = _sceneView

        setupMotionHandler()

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        _sceneView!.addGestureRecognizer(tapGesture)
        
        let swipeLeftGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe))
        swipeLeftGesture.direction = .left
        _sceneView!.addGestureRecognizer(swipeLeftGesture)

        let swipeRightGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe))
        swipeRightGesture.direction = .right
        _sceneView!.addGestureRecognizer(swipeRightGesture)

        let swipeDownGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe))
        swipeDownGesture.direction = .down
        _sceneView!.addGestureRecognizer(swipeDownGesture)

        let swipeUpGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe))
        swipeUpGesture.direction = .up
        _sceneView!.addGestureRecognizer(swipeUpGesture)
    }

    // -------------------------------------------------------------------------

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // -------------------------------------------------------------------------

}
