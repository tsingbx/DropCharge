//
//  Playing.swift
//  DropCharge
//
//  Created by xulingjiao on 2019/4/27.
//  Copyright © 2019 Sprite. All rights reserved.
//

import SpriteKit
import GameplayKit

class Playing: GKState {
    
    unowned let scene: GameScene
    
    init(scene: SKScene) {
        self.scene = scene as! GameScene
        super.init()
    }
    
    
    override func didEnter(from previousState: GKState?) {
        if previousState is WaitingForBomb {
            scene.player.physicsBody!.isDynamic = true
            scene.superBoostPlayer()
            scene.playBackgroundMusic(name: "bgMusic.mp3")
        }
    }
    
    override func update(deltaTime seconds: TimeInterval) {
        scene.updateCamera()
        scene.updateLevel()
        scene.updatePlayer()
        scene.updateLava(dt: seconds)
        scene.updateCollisionLava()
        scene.updateExplosions(dt: seconds)
        scene.updateRedAlert(lastUpdateTime: seconds)
    }
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass is GameOver.Type
    }
}
