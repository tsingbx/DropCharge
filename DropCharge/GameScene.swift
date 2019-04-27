//
//  GameScene.swift
//  DropCharge
//
//  Created by xulingjiao on 2019/4/18.
//  Copyright © 2019 Sprite. All rights reserved.
//

import SpriteKit
import CoreMotion
import GameplayKit

struct PhysicsCategory {
    static let None: UInt32 = 0
    static let Player: UInt32 = 0b1 //1
    static let PlatformNormal: UInt32 = 0b10 //2
    static let PlatformBreakable: UInt32 = 0b100 //4
    static let CoinNormal: UInt32 = 0b1000 //8
    static let CoinSpecial: UInt32 = 0b10000 //16
    static let Edges: UInt32 = 0b100000 //32
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    var bgNode = SKNode()
    var fgNode = SKNode()
    var background: SKNode!
    var backHeight: CGFloat = 0.0
    var player: SKSpriteNode!
    var platform5Across: SKSpriteNode!
    var platformBreakArrow: SKSpriteNode!
    var break5Across: SKSpriteNode!
    var coinArrow: SKSpriteNode!
    var coinSArrow: SKSpriteNode!
    var coinCross: SKSpriteNode!
    var coinDiagonal: SKSpriteNode!
    var coinS5Across: SKSpriteNode!
    var coinSCross: SKSpriteNode!
    var coinSDiagonal: SKSpriteNode!
    var platformArrow: SKSpriteNode!
    var platformDiagonal: SKSpriteNode!
    var breakDiagonal: SKSpriteNode!
    var coin5Across: SKSpriteNode!
    var lastItemPosition: CGPoint = CGPoint.zero
    var lastItemHeight: CGFloat = 0.0
    var levelY: CGFloat = 0.0
    let motionManager = CMMotionManager()
    var xAcceleration = CGFloat(0)
    var lava: SKSpriteNode!
    var lastUpdateTimeInterval: TimeInterval = 0
    var deltaTime: TimeInterval = 0
    var lives = 3
    lazy var gameState: GKStateMachine = GKStateMachine(states: [WaitingForTap(scene: self), WaitingForBomb(scene: self), Playing(scene: self), GameOver(scene: self)])
    lazy var playerState: GKStateMachine = GKStateMachine(states: [Idle(scene: self),Jump(scene: self), Fall(scene: self), Lava(scene: self), Dead(scene: self)])
    override func didMove(to view: SKView) {
        physicsWorld.contactDelegate = self
        setupNodes()
        setupLevel()
        //setupPlayer()
        playerState.enter(Idle.self)
        setupCoreMotion()
        setCameraPosition(position: CGPoint(x: size.width/2, y: size.height/2))
        gameState.enter(WaitingForTap.self)
    }
    
    func setupNodes() {
        let worldNode = childNode(withName: "World")!
        bgNode = worldNode.childNode(withName: "Background")!
        background = bgNode.childNode(withName: "Overlay")!.copy()
            as? SKNode
        backHeight = background.calculateAccumulatedFrame().height
        fgNode = worldNode.childNode(withName: "Foreground")!
        player = fgNode.childNode(withName: "Player") as? SKSpriteNode
        fgNode.childNode(withName: "Bomb")?.run(SKAction.hide())
        platform5Across = loadOverlayNode(fileName: "Platform5Across")
        break5Across = loadOverlayNode(fileName: "Break5Across")
        coinArrow = loadOverlayNode(fileName: "CoinArrow")
        coinSArrow = loadOverlayNode(fileName: "CoinSArrow")
        platformBreakArrow = loadOverlayNode(fileName: "BreakArrow");
        coinCross = loadOverlayNode(fileName: "CoinCross")
        coinDiagonal = loadOverlayNode(fileName: "CoinDiagonal")
        coinS5Across = loadOverlayNode(fileName: "CoinS5Across")
        coinSCross = loadOverlayNode(fileName: "CoinSCross")
        coinSDiagonal = loadOverlayNode(fileName: "CoinSDiagonal")
        platformArrow = loadOverlayNode(fileName: "PlatformArrow")
        platformDiagonal = loadOverlayNode(fileName: "PlatformDiagonal")
        breakDiagonal = loadOverlayNode(fileName: "BreakDiagonal")
        coin5Across = loadOverlayNode(fileName: "Coin5Across")
        let cameraNode = SKCameraNode()
        addChild(cameraNode)
        camera = cameraNode
        setupLava()
    }
    
    func setupLevel() {
        let initialPlatform = platform5Across.copy() as! SKSpriteNode
        var itemPosition = player.position
        itemPosition.y = player.position.y -
            ((player.size.height * 0.5) +
                (initialPlatform.size.height * 0.20))
        initialPlatform.position = itemPosition
        fgNode.addChild(initialPlatform)
        lastItemPosition = itemPosition
        lastItemHeight = initialPlatform.size.height / 2.0
        levelY = bgNode.childNode(withName: "Overlay")!.position.y + backHeight
        while lastItemPosition.y < levelY {
            addRandomOverlayNode()
        }
    }
    
    func updateLevel() {
        let cameraPos = getCameraPosition()
        if cameraPos.y > levelY - (size.height * 0.55) {
            createBackgroundNode()
            while lastItemPosition.y < levelY {
                addRandomOverlayNode()
            }
        }
    }
    
    func setupPlayer() {
        player.physicsBody = SKPhysicsBody(circleOfRadius: player.size.width*0.3)
        player.physicsBody!.isDynamic = false
        player.physicsBody!.allowsRotation = false
        player.physicsBody!.categoryBitMask = PhysicsCategory.Player
        player.physicsBody!.collisionBitMask = 0
    }
    
    func updatePlayer() {
        player.physicsBody?.velocity.dx = xAcceleration * 1000.0
        var playerPosition = convert(player.position, from: fgNode)
        if playerPosition.x < -player.size.width/2 {
            playerPosition = convert(CGPoint(x: size.width+player.size.width/2, y: 0.0), to: fgNode)
            player.position.x = playerPosition.x
        }
        else if playerPosition.x > size.width + player.size.width/2 {
            playerPosition = convert(CGPoint(x: -player.size.width/2, y: 0), to: fgNode)
            player.position.x = playerPosition.x
        }
        if player.physicsBody!.velocity.dy < 0 {
            playerState.enter(Fall.self)
        } else {
            playerState.enter(Jump.self)
        }
    }
    
    func updateLava(dt: TimeInterval) {
        let lowerLeft = CGPoint(x: 0, y: camera!.position.y - (size.height/2))
        let visibleMinYFg = scene!.convert(lowerLeft, to: fgNode).y
        let lavaVelocity = CGPoint(x: 0, y: 120)
        let lavaStep = lavaVelocity * CGFloat(dt)
        var newPosition = lava.position + lavaStep
        newPosition.y = max(newPosition.y, (visibleMinYFg - 125.0))
        lava.position = newPosition
    }
    
    func setupCoreMotion() {
        motionManager.accelerometerUpdateInterval = 0.2
        let queue = OperationQueue()
        motionManager.startAccelerometerUpdates(to: queue) { accelerometerData, error in
            guard let accelerometerData = accelerometerData else {
                return
            }
            let acceleration = accelerometerData.acceleration
            self.xAcceleration = (CGFloat(acceleration.x) * 0.75) + (self.xAcceleration * 0.25)
        }
    }
    
    func loadOverlayNode(fileName: String) -> SKSpriteNode {
        let overlayScene = SKScene(fileNamed: fileName)!
        let contentTemplateNode =
            overlayScene.childNode(withName: "Overlay")
        return contentTemplateNode as! SKSpriteNode
    }
    
    func createOverlayNode(nodeType: SKSpriteNode, flipX: Bool) {
        let platform = nodeType.copy() as! SKSpriteNode
        lastItemPosition.y = lastItemPosition.y +
            (lastItemHeight + (platform.size.height / 2.0))
        lastItemHeight = platform.size.height / 2.0
        platform.position = lastItemPosition
        if flipX == true {
            platform.xScale = -1.0
        }
        fgNode.addChild(platform)
    }
    
    func addRandomOverlayNode() {
        let overlaySprite: SKSpriteNode!
        let platformPercentage = CGFloat(100/14.0)
        let rnd = CGFloat.random(min: CGFloat(1), max: CGFloat(100))
        if rnd <= platformPercentage {
            overlaySprite = platform5Across
        }
        else if (rnd <= platformPercentage * 2) {
            overlaySprite = break5Across
        }
        else if (rnd <= platformPercentage * 3) {
            overlaySprite = coinSArrow
        }
        else if (rnd <= platformPercentage * 4) {
            overlaySprite = platformBreakArrow
        }
        else if (rnd <= platformPercentage * 5) {
            overlaySprite = coinCross
        }
        else if (rnd <= platformPercentage * 6) {
            overlaySprite = coinDiagonal
        }
        else if (rnd <= platformPercentage * 7) {
            overlaySprite = coinS5Across;
        }
        else if (rnd <= platformPercentage * 8) {
            overlaySprite = coinSCross
        }
        else if (rnd <= platformPercentage * 9) {
            overlaySprite = coinSDiagonal
        }
        else if (rnd <= platformPercentage * 10) {
            overlaySprite = platformArrow
        }
        else if (rnd <= platformPercentage * 11) {
            overlaySprite = platformDiagonal
        }
        else if (rnd <= platformPercentage * 12) {
            overlaySprite = breakDiagonal
        }
        else if (rnd <= platformPercentage * 13) {
            overlaySprite = coin5Across
        }
        else {
            overlaySprite = coinArrow
        }
        createOverlayNode(nodeType: overlaySprite, flipX: false)
    }
    
    func createBackgroundNode() {
        let backNode = background.copy() as! SKNode
        backNode.position = CGPoint(x: 0.0, y: levelY)
        bgNode.addChild(backNode)
        levelY += backHeight
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        switch gameState.currentState {
        case is WaitingForTap:
            gameState.enter(WaitingForBomb.self)
            self.run(SKAction.wait(forDuration: 2.0), completion: {
                self.gameState.enter(Playing.self)
            })
        case is GameOver:
            let newScene = GameScene(fileNamed: "GameScene")
            newScene!.scaleMode = .aspectFill
            let reveal = SKTransition.flipVertical(withDuration: 0.5)
            self.view?.presentScene(newScene!, transition: reveal)
        default:
            break
        }
    }
    
    func setPlayerVelocity(amount: CGFloat) {
        let gain: CGFloat = 2.5
        player.physicsBody!.velocity.dy = max(player.physicsBody!.velocity.dy, amount * gain)
    }
    
    func jumpPlayer() {
        setPlayerVelocity(amount: 650)
    }
    
    func boostPlayer() {
        setPlayerVelocity(amount: 1200)
    }
    
    func superBoostPlayer() {
        setPlayerVelocity(amount: 1700)
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        let other = contact.bodyA.categoryBitMask == PhysicsCategory.Player ? contact.bodyB : contact.bodyA
        switch other.categoryBitMask {
        case PhysicsCategory.CoinNormal:
            if let coin = other.node as? SKSpriteNode {
                coin.removeFromParent()
                jumpPlayer()
            }
        case PhysicsCategory.PlatformNormal:
            if let _ = other.node as? SKSpriteNode {
                if player.physicsBody!.velocity.dy < 0 {
                    jumpPlayer()
                }
            }
        case PhysicsCategory.PlatformBreakable:
            if let _ = other.node as? SKSpriteNode {
                //todo break
            }
        case PhysicsCategory.CoinSpecial:
            if let coin = other.node as? SKSpriteNode {
                coin.removeFromParent()
                superBoostPlayer()
            }
        default:
            break
        }
    }
    
    func overlapAmount() -> CGFloat {
        guard let view = self.view else {
            return 0
        }
        let scale = view.bounds.size.height / self.size.height
        let scaleWidth = self.size.width * scale
        let scaleOverlap = scaleWidth - view.bounds.size.width
        return scaleOverlap / scale
    }
    
    func getCameraPosition() -> CGPoint {
        return CGPoint(x: camera!.position.x + overlapAmount()/2, y: camera!.position.y)
    }
    
    func setCameraPosition(position: CGPoint) {
        camera!.position = CGPoint(x: position.x - overlapAmount()/2, y: position.y)
    }
    
    func updateCamera() {
        let cameraTarget = convert(player.position, from: fgNode)
        var targetPosition = CGPoint(x: getCameraPosition().x, y: cameraTarget.y - (scene!.view!.bounds.height * 0.4))
        let lavaPos = convert(lava.position, from: fgNode)
        targetPosition.y = max(targetPosition.y, lavaPos.y)
        let diff = targetPosition - getCameraPosition()
        let lerpValue = CGFloat(0.2)
        let lerpDiff = diff * lerpValue
        let newPosition = getCameraPosition() + lerpDiff
        setCameraPosition(position: CGPoint(x: size.width/2, y: newPosition.y))
    }
    
    func updateCollisionLava() {
        if player.position.y < lava.position.y + 180 {
            playerState.enter(Lava.self)
            if lives <= 0 {
                playerState.enter(Dead.self)
                gameState.enter(GameOver.self)
            }
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        if lastUpdateTimeInterval > 0 {
            deltaTime = currentTime - lastUpdateTimeInterval
        } else {
            deltaTime = 0
        }
        lastUpdateTimeInterval = currentTime
        if isPaused {
            return
        }
        gameState.update(deltaTime: deltaTime)
    }
    
    func explosition(intensity: CGFloat) -> SKEmitterNode {
        let emitter = SKEmitterNode()
        let particleTexture = SKTexture(imageNamed: "spark")
        emitter.zPosition = 2
        emitter.particleTexture = particleTexture
        emitter.particleBirthRate = 4000 * intensity
        emitter.numParticlesToEmit = Int(400 * intensity)
        emitter.particleLifetime = 2.0
        //emitter.particleLifetimeRange = 1.0
        emitter.emissionAngle = CGFloat(90.0).degreesToRadians()
        emitter.emissionAngleRange = CGFloat(360.0).degreesToRadians()
        emitter.particleSpeed = 600 * intensity
        emitter.particleSpeedRange = 1000 * intensity
        emitter.particleAlpha = 1.0
        emitter.particleAlphaRange = 0.25
        emitter.particleScale = 1.2
        emitter.particleScaleRange = 2.0
        emitter.particleScaleSpeed = -1.5
        //emitter.particleColor = SKColor.orange
        emitter.particleColorBlendFactor = 1
        emitter.particleBlendMode = SKBlendMode.add
        emitter.run(SKAction.removeFromParentAfterDelay(delay: 2.0))
        let sequence = SKKeyframeSequence(capacity: 5)
        sequence.addKeyframeValue(SKColor.white, time: 0)
        sequence.addKeyframeValue(SKColor.yellow, time: 0.1)
        sequence.addKeyframeValue(SKColor.orange, time: 0.15)
        sequence.addKeyframeValue(SKColor.red, time: 0.75)
        sequence.addKeyframeValue(SKColor.black, time: 0.95)
        emitter.particleColorSequence = sequence
        return emitter
    }
    
    func setupLava() {
        lava = fgNode.childNode(withName: "Lava") as? SKSpriteNode
        let emitter = SKEmitterNode(fileNamed: "Lava.sks")!
        emitter.particlePositionRange = CGVector(dx: size.width * 1.125, dy: 0.0)
        emitter.advanceSimulationTime(3.0)
        emitter.zPosition = 4
        lava.addChild(emitter)
    }
    
    func addTrail(name: String) -> SKEmitterNode {
        let trail = SKEmitterNode(fileNamed: name)!
        trail.targetNode = fgNode
        player.addChild(trail)
        return trail
    }
    
    func removeTrail(trail: SKEmitterNode) {
        trail.numParticlesToEmit = 1
        trail.run(SKAction.removeFromParentAfterDelay(delay: 1.0))
    }
}
