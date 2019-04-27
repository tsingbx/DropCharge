//
//  Fall.swift
//  DropCharge
//
//  Created by xulingjiao on 2019/4/27.
//  Copyright © 2019 Sprite. All rights reserved.
//

import SpriteKit
import GameplayKit

class Fall: GKState {
    
    unowned let scene: GameScene
    
    init(scene: SKScene) {
        self.scene = scene as! GameScene
        super.init()
    }
    
    override func didEnter(from previousState: GKState?) {
        print("Fall!")
    }
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass is Jump.Type || stateClass is Lava.Type
    }
}
