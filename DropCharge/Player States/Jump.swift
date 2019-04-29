//
//  Jump.swift
//  DropCharge
//
//  Created by xulingjiao on 2019/4/27.
//  Copyright © 2019 Sprite. All rights reserved.
//

import SpriteKit
import GameplayKit

class Jump: GKState {
    
    unowned let scene: GameScene
    
    init(scene: SKScene) {
        self.scene = scene as! GameScene
        super.init()
    }
    
    override func didEnter(from previousState: GKState?) {
        if previousState is Lava {
            return
        }
        if scene.playerTrail.particleBirthRate == 0 {
            scene.playerTrail.particleBirthRate = 200
        }
    }
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass is Fall.Type
    }
    
    override func update(deltaTime seconds: TimeInterval) {
        if abs(scene.player.physicsBody!.velocity.dx) > 100.0 {
            if (scene.player.physicsBody!.velocity.dx > 0) {
                scene.runAnim(anim: scene.animSteerRight)
            }
            else {
                scene.runAnim(anim: scene.animSteerLeft)
            }
        }
        else {
            scene.runAnim(anim: scene.animJump)
        }
    }
    
}
