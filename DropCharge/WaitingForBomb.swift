//
//  WaitingForBomb.swift
//  DropCharge
//
//  Created by xulingjiao on 2019/4/27.
//  Copyright © 2019 Sprite. All rights reserved.
//

import SpriteKit
import GameplayKit

class WaitingForBomb: GKState {
    unowned let scene: GameScene
    
    init(scene: SKScene) {
        self.scene = scene as! GameScene
        super.init()
    }
    
    override func didEnter(from previousState: GKState?) {
        if previousState is WaitingForTap {
            let scale = SKAction.scale(to: 0, duration: 0.4)
            scene.fgNode.childNode(withName: "Title")!.run(scale)
            scene.fgNode.childNode(withName: "Ready")!.run(SKAction.sequence([SKAction.wait(forDuration: 0.2), scale]))
            let bomb = scene.fgNode.childNode(withName: "Bomb")!
            let scaleUp = SKAction.scale(to: 1.25, duration: 0.25)
            let scaleDown = SKAction.scale(to: 1.0, duration: 0.25)
            let sequence = SKAction.sequence([scaleUp, scaleDown])
            let repeatSeq = SKAction.repeatForever(sequence)
            bomb.run(SKAction.unhide())
            bomb.run(repeatSeq)
        }
    }
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass is Playing.Type
    }
    
    override func willExit(to nextState: GKState) {
        if nextState is Playing {
            scene.fgNode.childNode(withName: "Bomb")!.removeFromParent()
        }
    }
}