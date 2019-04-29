//
//  Lava.swift
//  DropCharge
//
//  Created by xulingjiao on 2019/4/27.
//  Copyright © 2019 Sprite. All rights reserved.
//

import SpriteKit
import GameplayKit

class Lava: GKState {
    
    unowned let scene: GameScene
    
    init(scene: SKScene) {
        self.scene = scene as! GameScene
        super.init()
    }
    
    override func didEnter(from previousState: GKState?) {
        scene.playerTrail.particleBirthRate = 0
        scene.run(scene.soundHitLava)
        let smokeTrail = scene.addTrail(name: "SmokeTrail")
        scene.run(SKAction.sequence([SKAction.wait(forDuration: 3.0), SKAction.run({
            self.scene.removeTrail(trail: smokeTrail)
        })]))
        scene.boostPlayer()
        scene.lives -= 1
        scene.screenShakeByAmt(amt: 50)
    }
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass is Jump.Type || stateClass is Fall.Type || stateClass is Dead.Type
    }
}
