//
//  Player.swift
//
//  Created by 董震宇 on 2020/12/4.
//

import SceneKit

// -----------------------------------------------------------------------------

class Enemy : Plane {
    
    // -------------------------------------------------------------------------
    // MARK: - Propertiues
    
    override var description: String {
        get {
            return "enemy \(self.id)"
        }
    }

    // -------------------------------------------------------------------------
    // MARK: - Actions

    override func hit() {
        if let emitter = SCNParticleSystem(named: "art.scnassets/smoke.scnp", inDirectory: nil) {
            self.addParticleSystem(emitter)
        }
        
        moveDown()
        moveDown()
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 1.0
        
        self.modelNode?.eulerAngles = SCNVector3(degreesToRadians(value: 40.0), degreesToRadians(value: 0.0), 0)
        
        SCNTransaction.commit()
    }
    
    // -------------------------------------------------------------------------
    
    override func start() {
        super.start()
        moveUp()
    }

    // -------------------------------------------------------------------------

    func fire(_ level: GameLevel) {
        if self.numberOfBullets == 0 {
            Debug("\(self) has no bullets anymore")
            return
        }

        var position = self.position
        position.z = position.z + 1.0
        
        GameSound.fire(self)
        
        // Create bullet and fire
        self.numberOfBullets -= 1
        let bullet = level.fireBullet(enemy: true, position: position, sideDistance: 0, fallDistance: 0)
        
        Debug("\(self) has fired bullet \(bullet)")
    }

    // -------------------------------------------------------------------------
    // MARK: - Game loop
    
    override func update(atTime time: TimeInterval, level: GameLevel) {
        super.update(atTime: time, level: level)
        
        if self.playerIsInDistance(level.player) && self.numberOfBullets > 0 {
            self.fire(level)
        }
    }

    // -------------------------------------------------------------------------
    // MARK: - Helper methods
    
    private func playerIsInDistance(_ player: Player?) -> Bool {
        if player == nil {
            return false
        }
        
        if self.position.distance(to: player!.position) <= Game.Plane.fireDistance {
            return true
        }
        
        return false
    }
    

    // -------------------------------------------------------------------------
    // MARK: - Initialisation
    
    override init() {
        super.init()
        
        // Set physics
        self.collissionNode!.name = "enemy-plane"
        self.collissionNode!.physicsBody?.categoryBitMask = Game.Physics.Categories.enemy
        
        self.flip = true
        
        self.state = .alive
        self.points = Game.Points.enemy
        self.numberOfBullets = Game.Bullets.enemy
    }
    
    // -------------------------------------------------------------------------
    
    required init(coder: NSCoder) {
        fatalError("Not yet implemented")
    }
    
    // -------------------------------------------------------------------------
    
}

