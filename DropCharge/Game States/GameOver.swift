//
//  GameOver.swift
//  DropCharge
//
//  Created by xulingjiao on 2019/4/27.
//  Copyright © 2019 Sprite. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameOver: GKState {
    
    unowned let scene: GameScene
    
    init(scene: SKScene) {
        self.scene = scene as! GameScene
        super.init()
    }
    
    override func didEnter(from previousState: GKState?) {
        if previousState is Playing {
            scene.playBackgroundMusic(name: "SpaceGame.caf")
            scene.physicsWorld.contactDelegate = nil
            scene.player.physicsBody?.isDynamic = false
            let moveUpAction = SKAction.moveBy(x: 0, y: scene.size.height/2, duration: 0.5)
            moveUpAction.timingMode = .easeOut
            let moveDownAction = SKAction.moveBy(x: 0, y: -(scene.size.height * 1.5), duration: 1.0)
            moveDownAction.timingMode = .easeIn
            let sequence = SKAction.sequence([moveUpAction, moveDownAction])
            scene.player.run(sequence)
            let gameOver = SKSpriteNode(imageNamed: "GameOver")
            gameOver.position = scene.getCameraPosition()
            gameOver.zPosition = 10
            scene.addChild(gameOver)
            
            let explosion = scene.explosition(intensity: 3.0)
            explosion.position = gameOver.position
            explosion.zPosition = 11
            scene.addChild(explosion)
            scene.run(scene.soundExplosions[3])
        }
    }
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass is WaitingForTap.Type
    }
}
