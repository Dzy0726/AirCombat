//
//  GameLevel.swift
//
//  Created by 董震宇 on 2020/12/1.
//

import UIKit
import SceneKit

enum GameState {
    case initialized, ready, play, win, loose, stopped
}

// -----------------------------------------------------------------------------

class GameLevel: SCNScene, SCNPhysicsContactDelegate {
    //A list of all game objects
    private var _gameObjects = Array<GameObject>()

    //A list of all bullets
    private var _bullets = Array<Bullet>()
    
    private var _terrain: Terrain?
    private var _player: Player?
    private var _hud: HUD?

    private var _touchedRings = 0
    
    private var _missedRings = 0

    //the game becomes different states
    private var _state = GameState.initialized

    // -------------------------------------------------------------------------
    // MARK: - Properties

    var hud: HUD? {
        get {
            return _hud
        }
        set(value) {
            _hud = value
        }
    }

    // -------------------------------------------------------------------------
    
    var state: GameState {
        get {
            return _state
        }
        set(value) {
            Debug("State of level changed from \(_state) to \(value)")
            _state = value
        }
    }

    // -------------------------------------------------------------------------
    
    var player: Player? {
        get {
            return _player
        }
    }

    // -------------------------------------------------------------------------
    // MARK: Motion handling
    
    func motionMoveUp() {
        _player!.moveUp()
    }
    
    // -------------------------------------------------------------------------
    
    func motionMoveDown() {
        _player!.moveDown()
    }
    
    // -------------------------------------------------------------------------
    
    func motionStopMovingUpDown() {
        _player!.stopMovingUpDown()
    }
    
    // -------------------------------------------------------------------------
    
    func motionMoveLeft() {
        _player!.moveLeft()
    }
    
    // -------------------------------------------------------------------------
    
    func motionMoveRight() {
        _player!.moveRight()
    }
    
    // -------------------------------------------------------------------------
    
    func motionStopMovingLeftRight() {
        _player!.stopMovingLeftRight()
    }

    // -------------------------------------------------------------------------
    // MARK: - Input handling
    
    func swipeLeft() {
        _player!.moveLeft()
    }

    // -------------------------------------------------------------------------
    
    func swipeRight() {
        _player!.moveRight()
    }

    // -------------------------------------------------------------------------
    
    func swipeDown() {
        _player!.moveDown()
    }

    // -------------------------------------------------------------------------
    
    func swipeUp() {
        _player!.moveUp()
    }

    // -------------------------------------------------------------------------
    
    func fire() {
        _player!.fire(self)
    }

    // -------------------------------------------------------------------------
    // MARK: - Points system
    
    func addPoints(_ points: Int) {
        _hud?.addPoints(points)
    }

    // -------------------------------------------------------------------------

    func fireBullet(enemy: Bool, position: SCNVector3, sideDistance: CGFloat = 0, fallDistance: CGFloat = 0) -> Bullet {
        let direction : PlaneDirection = enemy ? .down : .up
        
        // Search in list if we have an unused bullet
        for bullet in _bullets {
            if (bullet.state == .died && bullet.enemy == enemy) {
            
                bullet.isHidden = false
                bullet.state = .initialized
                
                bullet.position = position
                bullet.fire(direction: direction, sideDistance: sideDistance, fallDistance: fallDistance, speed: 3.0)

                Debug("Reuse bullet \(bullet)")
                return bullet
            }
        }
        
        // No bullets free, so create one
        let bullet = Bullet(enemy: enemy)
        _bullets.append(bullet)
        self.rootNode.addChildNode(bullet)

        bullet.position = position
        bullet.fire(direction: direction, sideDistance: sideDistance, fallDistance: fallDistance, speed: 3.0)
        
        return bullet
    }

    // -------------------------------------------------------------------------

    func flyTrough(_ ring: Ring) {
        _touchedRings += 1
        _hud?.rings = _touchedRings
        
        self.addPoints(ring.points)
    }

    // -------------------------------------------------------------------------
    
    func touchedHandicap(_ handicap: Handicap) {
        _hud?.message("GAME OVER", information: "- Touch to restart - ")
        
        self.state = .loose
    }

    // -------------------------------------------------------------------------
    
    func crashed() {
        _hud?.message("GAME OVER", information: "- Touch to restart - ")
        
        self.state = .loose
    }

    // -------------------------------------------------------------------------
    // MARK: - Game loop
    
    func update(atTime time: TimeInterval) {

        if self.state != .play {
            return
        }
        
        var missedRings = 0
        
        for object in _gameObjects {
            object.update(atTime: time, level: self)

           
            if let ring = object as? Ring {
                if (ring.presentation.position.z + 5.0) < _player!.presentation.position.z {
                    if ring.state == .alive {
                        missedRings += 1
                    }
                }
            }
        }
        
        if missedRings > _missedRings {
            _missedRings = missedRings
            _hud?.missedRings = _missedRings
        }
        
        // Test for end of game
        if _missedRings + _touchedRings == Game.Level.numberOfRings {
            if _missedRings < 3 {
                _hud?.message("YOU WIN", information: "- Touch to restart - ")
            }
            else {
                _hud?.message("TRY TO IMPROVE", information: "- Touch to restart - ")
            }

            self.state = .win
            _player!.stop()
        }
    }

    // -------------------------------------------------------------------------
    // MARK: - Physics delegate

    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        //  Call collision handler of the object
        if let gameObjectA = contact.nodeA.parent as? GameObject, let gameObjectB = contact.nodeB.parent as? GameObject {
            gameObjectA.collision(with: gameObjectB, level: self)
            gameObjectB.collision(with: gameObjectA, level: self)
        }
    }

    // -------------------------------------------------------------------------
    // MARK: - Place objects

    private func addRings() {
        // Add rings to the game level
        let space = Int(Game.Level.length-Game.Level.start) / Int(Game.Level.numberOfRings+1)
        
        for i in 1...Game.Level.numberOfRings {
            let ring = Ring(number: i)
            
            var x: CGFloat = Game.Level.width/2
            let rnd = Random.integer(1, 3)
            if rnd == 1 {
                x = x - Game.Objects.offset
            }
            else if rnd == 3 {
                x = x + Game.Objects.offset
            }
            
            let height = Random.integer(8, 20)
            
            ring.position = SCNVector3(Int(x), height, Int(Game.Level.start)+i*space)
            self.rootNode.addChildNode(ring)
            
            _gameObjects.append(ring)
        }
    }

    // -------------------------------------------------------------------------

    private func addEnemies() {
        // Add enemies to the game level
        let space = Int(Game.Level.length-Game.Level.start) / Int(Game.Level.numberOfEnemies+1)
        
        for i in 1...Game.Level.numberOfEnemies {
            let enemy = Enemy()
            
            var x: CGFloat = Game.Level.width/2
            let rnd = Random.integer(1, 3)
            if rnd == 1 {
                x = x - Game.Objects.offset
            }
            else if rnd == 3 {
                x = x + Game.Objects.offset
            }
            
            enemy.position = SCNVector3(Int(x), Int(Game.Plane.minimumHeight), Int(Game.Level.length/3)+i*space)
            self.rootNode.addChildNode(enemy)
            
            _gameObjects.append(enemy)
        }
    }

    // -------------------------------------------------------------------------

    private func addHandicap(x: CGFloat, z: CGFloat) {
        let handicap = Handicap()
        handicap.position = SCNVector3(x, handicap.height/2, z)
        self.rootNode.addChildNode(handicap)
        
        _gameObjects.append(handicap)
    }

    // -------------------------------------------------------------------------

    private func addHandicaps() {
        //Add handicaps to the game level
        let space = CGFloat(Game.Level.length-Game.Level.start) / CGFloat(Game.Level.numberOfRings+1)
        
        for i in 1...Game.Level.numberOfRings-1 {
            var x: CGFloat = Game.Level.width/2
            let rnd = Random.integer(1, 3)
            
            if rnd == 1 {
                x = x - Game.Objects.offset
                
                addHandicap(x: x-Random.cgFloat(10, 50), z: Game.Level.start+CGFloat(i)*space + space/2.0)
                addHandicap(x: x+Game.Objects.offset+Random.cgFloat(10, 50), z: Game.Level.start+CGFloat(i)*space + space/2.0)
            }
            else if rnd == 3 {
                x = x + Game.Objects.offset
                
                addHandicap(x: x+Random.cgFloat(10, 50), z: Game.Level.start+CGFloat(i)*space + space/2.0)
                addHandicap(x: x-Game.Objects.offset-Random.cgFloat(10, 50), z: Game.Level.start+CGFloat(i)*space + space/2.0)
            }
            
            addHandicap(x: x, z: Game.Level.start+CGFloat(i)*space + space/2.0)
        }
    }

    // -------------------------------------------------------------------------

    private func addPlayer() {
        _player = Player()
        
        _player!.position = SCNVector3(Game.Level.width/2, CGFloat(Game.Plane.minimumHeight), Game.Level.start)
        self.rootNode.addChildNode(_player!)
        
        _gameObjects.append(_player!)
    }
    
    // -------------------------------------------------------------------------
    
    private func addTerrain() {
        // Create terrain
        _terrain = Terrain(width: Int(Game.Level.width), length: Int(Game.Level.length), scale: 96)
        
        let generator = PerlinNoiseGenerator(seed: nil)
        _terrain?.formula = {(x: Int32, y: Int32) in
            return generator.valueFor(x: x, y: y)
        }
        
        _terrain!.create(withColor: UIColor.green)
        _terrain!.position = SCNVector3Make(0, 0, 0)
        self.rootNode.addChildNode(_terrain!)
    }

    // -------------------------------------------------------------------------

    private func addLights() {
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        ambientLightNode.light!.color = UIColor(hex:"#444444")
        self.rootNode.addChildNode(ambientLightNode)
    }
    
    // -------------------------------------------------------------------------
    // MARK: - Stop
    
    func stop() {
        // Stop all!
        for object in _gameObjects {
            object.stop()
        }
        
        self.physicsWorld.contactDelegate = nil
        self.hud = nil
        self.state = .stopped
    }

    // -------------------------------------------------------------------------

    func start() {
        if self.state == .ready {
            self.state = .play
            _hud?.reset()

            for object in _gameObjects {
                object.start()
            }
        }
    }

    // -------------------------------------------------------------------------
    // MARK: - Initialisation

    func create() {
        //  A skybox is used to show a game's background
        self.background.contents = UIImage(named: "art.scnassets/skybox")

        // Add fog effect
        self.fogStartDistance = Game.Level.Fog.start
        self.fogEndDistance = Game.Level.Fog.end
        
        addLights()
        
        addTerrain()
        addRings()
        addHandicaps()
        addEnemies()
        addPlayer()
        
        self.state = .ready
    }
    
    // -------------------------------------------------------------------------
    
    override init() {
        super.init()
        
        self.physicsWorld.contactDelegate = self
    }
    
    // -------------------------------------------------------------------------
    
    required init(coder: NSCoder) {
        fatalError("Not yet implemented")
    }
    
    // -------------------------------------------------------------------------
    
}
