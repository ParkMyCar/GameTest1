//
//  GameScene.swift
//  GameTest1
//
//  Created by Parker Timmerman on 1/22/17.
//  Copyright © 2017 Parker Timmerman. All rights reserved.
//

import SpriteKit
import GameplayKit

struct PhysicsCategory {
    static let ghost : UInt32 = 0x1 << 1
    static let ground : UInt32 = 0x1 << 2
    static let wall : UInt32 = 0x1 << 3
    static let score : UInt32 = 0x1 << 4
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var _ground = SKSpriteNode()
    var _ghost = SKSpriteNode()
    var _wallPair = SKNode()
    
    var moveAndRemove = SKAction()
    var gameStarted = Bool()
    
    var score = Int()
    let scoreLabel = SKLabelNode()
    
    var died = Bool()
    
    var restartButton = SKSpriteNode()
    
    func restartScene()
    {
        self.removeAllChildren()
        self.removeAllActions()
        died = false
        gameStarted = false
        score = 0
        createScene()
    }
    
    func createScene()
    {
        self.physicsWorld.contactDelegate = self                    //says we will handle physics contacts
        
        for i in 0..<2
        {
            let background = SKSpriteNode(imageNamed: "Background")
            background.anchorPoint = CGPoint(x: 0, y: 0)
            background.position = CGPoint(x: CGFloat(i-1) * self.frame.width, y: -self.frame.width)
            background.size = (self.view?.bounds.size)!
            background.name = "background"
            self.addChild(background)
        }
        
        scoreLabel.position = CGPoint(x: 0, y: 150)
        scoreLabel.text = "\(score)"
        scoreLabel.fontColor = UIColor.black
        scoreLabel.fontSize = 60
        scoreLabel.fontName = "04b_19"
        
        scoreLabel.zPosition = 5
        
        _ground = SKSpriteNode(imageNamed: "Ground")                //associating an image with the sprite
        _ground.setScale(0.5)
        
        _ground.position = CGPoint(x: 0, y: (-(scene?.size.height)! / 2) + _ground.size.height / 2)   //set position of the ground's center to be middle of screen
        _ground.physicsBody = SKPhysicsBody(rectangleOf: _ground.size)
        _ground.physicsBody?.categoryBitMask = PhysicsCategory.ground
        _ground.physicsBody?.collisionBitMask = PhysicsCategory.ghost
        _ground.physicsBody?.contactTestBitMask = PhysicsCategory.ghost
        _ground.physicsBody?.affectedByGravity = false
        _ground.physicsBody?.isDynamic = false
        
        _ground.zPosition = 3
        
        self.addChild(_ground) //adding ground to the scene
        
        _ghost = SKSpriteNode(imageNamed: "Ghost")
        _ghost.size = CGSize(width: 70, height: 70)
        _ghost.position = CGPoint(x: -10, y: 0)
        
        _ghost.physicsBody = SKPhysicsBody(circleOfRadius: _ghost.frame.height / 2)
        _ghost.physicsBody?.categoryBitMask = PhysicsCategory.ghost
        _ghost.physicsBody?.collisionBitMask = PhysicsCategory.wall | PhysicsCategory.ground
        _ghost.physicsBody?.contactTestBitMask = PhysicsCategory.wall | PhysicsCategory.ground | PhysicsCategory.score
        _ghost.physicsBody?.affectedByGravity = true
        _ghost.physicsBody?.isDynamic = true
        
        _ghost.zPosition = 2
        
        self.addChild(_ghost)
        self.addChild(scoreLabel)
    }
    
    override func didMove(to view: SKView)
    {
        createScene()
    }
    
    func createButton()
    {
        restartButton = SKSpriteNode(imageNamed: "RestartBtn")
        restartButton.size = CGSize(width: 200, height: 100)
        restartButton.position = CGPoint(x: 0, y: 100)
        restartButton.zPosition = 6
        restartButton.setScale(0)
        self.addChild(restartButton)
        
        restartButton.run(SKAction.scale(to: 1.0, duration: 0.2))
    }
    
    func didBegin(_ contact: SKPhysicsContact)
    {
        let firstBody = contact.bodyA
        let secondBody = contact.bodyB
        
        if firstBody.categoryBitMask == PhysicsCategory.score && secondBody.categoryBitMask == PhysicsCategory.ghost || firstBody.categoryBitMask == PhysicsCategory.ghost && secondBody.categoryBitMask == PhysicsCategory.score
        {
            score += 1
            print(score)
            scoreLabel.text = "\(score)"
        }
        
        if firstBody.categoryBitMask == PhysicsCategory.ghost && secondBody.categoryBitMask == PhysicsCategory.wall || firstBody.categoryBitMask == PhysicsCategory.wall && secondBody.categoryBitMask == PhysicsCategory.ghost
        {
            enumerateChildNodes(withName: "wallPair", using: ({
                (node, error) in
                node.speed = 0
                self.removeAllActions()
            }))
            
            if died == false
            {
                died = true
                createButton()
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        if gameStarted == false
        {
            gameStarted = true
            let spawn = SKAction.run({
                () in
                
                self.createWalls()
            })
            
            let delay = SKAction.wait(forDuration: 2.0)
            let spawnDelay = SKAction.sequence([spawn, delay])
            let spawnDelayForever = SKAction.repeatForever(spawnDelay)
            self.run(spawnDelayForever)
            
            let distance = CGFloat(self.frame.width * 2 + _wallPair.frame.width)
            let movePipes = SKAction.moveBy(x: -distance, y: 0, duration: TimeInterval(0.008 * distance))
            let removePipes = SKAction.removeFromParent()
            moveAndRemove = SKAction.sequence([movePipes, removePipes])
            
            _ghost.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
            _ghost.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 90))
        }
        else
        {
            if died == true
            {
                
            }
            else
            {
                _ghost.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
                _ghost.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 90))
            }
        }
        
        for touch in touches
        {
            let location = touch.location(in: self)
            
            if died == true
            {
                if restartButton.contains(location)
                {
                    restartScene()
                }
            }
        }
    }
    
    
    override func update(_ currentTime: TimeInterval)
    {
        // Called before each frame is rendered
        if gameStarted == true{
            if died == false
            {
                enumerateChildNodes(withName: "background", using: ({
                    (node, error) in
                    let bg = node as! SKSpriteNode
                    bg.position = CGPoint(x: bg.position.x - 2, y: bg.position.y)
                    
                    if bg.position.x <= -bg.size.width
                    {
                        bg.position = CGPoint(x: bg.position.x + bg.size.width, y: bg.position.y)
                    }
                }))
            }
        }
    }
    
    func createWalls()
    {
        let scoreNode = SKSpriteNode()
        scoreNode.size = CGSize(width: 1, height: 200)
        scoreNode.position = CGPoint(x: 500, y: 0)
        scoreNode.physicsBody = SKPhysicsBody(rectangleOf: scoreNode.size)
        scoreNode.physicsBody?.affectedByGravity = false;
        scoreNode.physicsBody?.isDynamic = false;
        scoreNode.physicsBody?.categoryBitMask = PhysicsCategory.score
        scoreNode.physicsBody?.collisionBitMask = 0
        scoreNode.physicsBody?.contactTestBitMask = PhysicsCategory.ghost
        scoreNode.color = SKColor.blue
      
        _wallPair = SKNode()
        _wallPair.name = "wallPair"
        
        let topWall = SKSpriteNode(imageNamed: "wall")
        let bottomWall = SKSpriteNode(imageNamed: "wall")
        
        topWall.physicsBody = SKPhysicsBody(rectangleOf: topWall.size)
        topWall.physicsBody?.categoryBitMask = PhysicsCategory.wall
        topWall.physicsBody?.collisionBitMask = PhysicsCategory.ghost
        topWall.physicsBody?.contactTestBitMask = PhysicsCategory.ghost
        topWall.physicsBody?.affectedByGravity = false
        topWall.physicsBody?.isDynamic = false
        
        bottomWall.physicsBody = SKPhysicsBody(rectangleOf: topWall.size)
        bottomWall.physicsBody?.categoryBitMask = PhysicsCategory.wall
        bottomWall.physicsBody?.collisionBitMask = PhysicsCategory.ghost
        bottomWall.physicsBody?.contactTestBitMask = PhysicsCategory.ghost
        bottomWall.physicsBody?.affectedByGravity = false
        bottomWall.physicsBody?.isDynamic = false
        
        topWall.position = CGPoint(x: 500, y: 400)
        bottomWall.position = CGPoint(x: 500, y: -400)
        
        topWall.setScale(0.5)
        bottomWall.setScale(0.5)
        
        topWall.zRotation = CGFloat(M_PI)
        
        _wallPair.addChild(topWall)
        _wallPair.addChild(bottomWall)
        _wallPair.addChild(scoreNode)
        
        _wallPair.zPosition = 1
        
        _wallPair.run(moveAndRemove)
        
        self.addChild(_wallPair)
    }
}
