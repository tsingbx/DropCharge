//
//  Idle.swift
//  DropCharge
//
//  Created by xulingjiao on 2019/4/27.
//  Copyright © 2019 Sprite. All rights reserved.
//

import SpriteKit
import GameplayKit

class Idle: GKState {
    
    unowned let scene: GameScene
    
    init(scene: SKScene) {
        self.scene = scene as! GameScene
        super.init()
    }
    
    override func didEnter(from previousState: GKState?) {
        scene.player.physicsBody = SKPhysicsBody(circleOfRadius: scene.player.size.width*0.3)
        scene.player.physicsBody!.isDynamic = false
        scene.player.physicsBody!.allowsRotation = false
        scene.player.physicsBody!.categoryBitMask = PhysicsCategory.Player
        scene.player.physicsBody!.collisionBitMask = 0
        scene.playerTrail = scene.addTrail(name: "PlayerTrail")
    }

}
