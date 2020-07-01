//
//  GameScene.swift
//  FlappyBird
//
//  Created by 吉和　匠 on 2020/06/05.
//  Copyright © 2020 SHO Yoshiwa. All rights reserved.
//

import SpriteKit
import AVFoundation

class GameScene: SKScene,SKPhysicsContactDelegate {
    
//    var itemPlayer: AVAudioPlayer!
    let playSound = SKAction.playSoundFileNamed("itemSound.mp3", waitForCompletion: false)
    
    var scrollNode:SKNode!
    var wallNode:SKNode!
    var bird:SKSpriteNode!
    var itemNode:SKNode!

    let birdCategory: UInt32 = 1 << 0
    let groundCategory: UInt32 = 1 << 1
    let wallCategory: UInt32 = 1 << 2
    let scoreCategory: UInt32 = 1 << 3
    let itemScoreCategory: UInt32 = 1 << 4
    
    var score = 0
    var itemScore = 0
    var scoreLabelNode:SKLabelNode!
    var bestScoreLabelNode:SKLabelNode!
    var itemScoreLabelNode:SKLabelNode!
    let userDefaults:UserDefaults = UserDefaults.standard
    
    override func didMove(to view: SKView) {
        
        physicsWorld.gravity = CGVector(dx: 0, dy: -4)
        physicsWorld.contactDelegate = self
        
        backgroundColor = UIColor(red: 0.15, green: 0.75, blue: 0.90, alpha: 1)
    
        scrollNode = SKNode()
        addChild(scrollNode)
        
        wallNode = SKNode()
        scrollNode.addChild(wallNode)
        
        itemNode = SKNode()
        scrollNode.addChild(itemNode)
        
        setupGround()
        setupCloud()
        setupWall()
        setupBird()
        setupItem()
        
        setupScoreLabel()
        
        
//        let itemSoundURL = Bundle.main.url(forResource: "itemSound", withExtension: "mp3")
//        do {
//            itemPlayer = try AVAudioPlayer(contentsOf: itemSoundURL!)
//        } catch {
//            print("error...")
//        }
        
    }
     
    func setupGround() {
        
        let groundTexture = SKTexture(imageNamed: "ground")
        groundTexture.filteringMode = .nearest
        
        let needNumber = Int(self.frame.size.width / groundTexture.size().width) + 2

        let moveGround = SKAction.moveBy(x: -groundTexture.size().width , y:0 , duration: 5)

        let resetGround = SKAction.moveBy(x: groundTexture.size().width, y: 0, duration: 0)

        let repeatScrollGround = SKAction.repeatForever(SKAction.sequence([moveGround , resetGround]))

        for i in 0..<needNumber {
            let sprite = SKSpriteNode(texture: groundTexture)

            sprite.position = CGPoint(
                x: groundTexture.size().width / 2 + groundTexture.size().width * CGFloat(i),
                y: groundTexture.size().height / 2
            )

            sprite.run(repeatScrollGround)

            sprite.physicsBody = SKPhysicsBody(rectangleOf: groundTexture.size())
            
            sprite.physicsBody?.categoryBitMask = groundCategory
            
            sprite.physicsBody?.isDynamic = false
            
            scrollNode.addChild(sprite)
        }
    }
    
    func setupCloud() {
        let cloudTexture = SKTexture(imageNamed: "cloud")
        cloudTexture.filteringMode = .nearest
        
        let needCloudNumber = Int(self.frame.size.width / cloudTexture.size().width) + 2
        
        let moveCloud = SKAction.moveBy(x: -cloudTexture.size().width , y:0 , duration: 20)

        let resetCloud = SKAction.moveBy(x: cloudTexture.size().width, y: 0, duration: 0)

        let repeatScrollCloud = SKAction.repeatForever(SKAction.sequence([moveCloud , resetCloud]))

        for i in 0..<needCloudNumber {
            let sprite = SKSpriteNode(texture: cloudTexture)
            sprite.zPosition = -100

            sprite.position = CGPoint(
                x: cloudTexture.size().width / 2 + cloudTexture.size().width * CGFloat(i),
                y: self.size.height - cloudTexture.size().height / 2
            )

            sprite.run(repeatScrollCloud)

            scrollNode.addChild(sprite)
        }
    }
        
    func setupWall() {
        
        let wallTexture = SKTexture(imageNamed: "wall")
        wallTexture.filteringMode = .linear
        
        let movingDistance = CGFloat(self.frame.size.width + wallTexture.size().width)
        
        let moveWall = SKAction.moveBy(x: -movingDistance, y: 0, duration: 4)
        
        let removeWall = SKAction.removeFromParent()
        
        let wallAnimation = SKAction.sequence([moveWall, removeWall])
        
        let birdSize = SKTexture(imageNamed: "bird_a").size()
        
        let slit_length = birdSize.height * 3
        
        let ramdom_y_range = birdSize.height * 3
        
        let groundSize = SKTexture(imageNamed: "ground").size()
        let center_y = groundSize.height + (self.frame.size.height - groundSize.height) / 2
        let under_wall_lowest_y = center_y - slit_length / 2 - wallTexture.size().height / 2 - ramdom_y_range / 2
        
        let createWallAnimation = SKAction.run({

            let wall = SKNode()
            wall.position = CGPoint(x: self.frame.size.width + wallTexture.size().width / 2, y: 0)
            wall.zPosition = -50

            let ramdom_y = CGFloat.random(in: 0..<ramdom_y_range)
            let under_wall_y = under_wall_lowest_y + ramdom_y

            let under = SKSpriteNode(texture: wallTexture)
            under.position = CGPoint(x: 0, y: under_wall_y)

            under.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            under.physicsBody?.categoryBitMask = self.wallCategory

            under.physicsBody?.isDynamic = false

            wall.addChild(under)

            let upper = SKSpriteNode(texture: wallTexture)
            upper.position = CGPoint(x: 0, y: under_wall_y + wallTexture.size().height + slit_length)

            upper.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            upper.physicsBody?.categoryBitMask = self.wallCategory

            upper.physicsBody?.isDynamic = false

            wall.addChild(upper)

            let scoreNode = SKNode()
            scoreNode.position = CGPoint(x: upper.size.width + birdSize.width / 2, y: self.frame.height / 2)
            scoreNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: upper.size.width, height: self.frame.size.height))
            scoreNode.physicsBody?.isDynamic = false
            scoreNode.physicsBody?.categoryBitMask = self.scoreCategory
            scoreNode.physicsBody?.contactTestBitMask = self.birdCategory

            wall.addChild(scoreNode)

            wall.run(wallAnimation)

            self.wallNode.addChild(wall)

        })
        
        let waitAnimation = SKAction.wait(forDuration: 2)
        
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createWallAnimation, waitAnimation]))

        wallNode.run(repeatForeverAnimation)
        }

    func setupBird() {

            let birdTextureA = SKTexture(imageNamed: "bird_a")
            birdTextureA.filteringMode = .linear
            let birdTextureB = SKTexture(imageNamed: "bird_b")
            birdTextureB.filteringMode = .linear

            let texturesAnimation = SKAction.animate(with: [birdTextureA, birdTextureB], timePerFrame: 0.2)
            let flap = SKAction.repeatForever(texturesAnimation)

            bird = SKSpriteNode(texture: birdTextureA)
            bird.position = CGPoint(x:self.frame.size.width * 0.2 , y: frame.size.height * 0.7)
            
            bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height / 2)

            bird.physicsBody?.allowsRotation = false
            
            bird.physicsBody?.categoryBitMask = birdCategory
            bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
            bird.physicsBody?.contactTestBitMask = groundCategory | wallCategory
            
            bird.run(flap)

            addChild(bird)
        }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if scrollNode.speed > 0 {
             bird.physicsBody?.velocity = CGVector.zero

            bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 15))
        } else if bird.speed == 0 {
            restart()
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        if scrollNode.speed <= 0 {
            return
        }
        
        if (contact.bodyA.categoryBitMask & scoreCategory) == scoreCategory || (contact.bodyB.categoryBitMask & scoreCategory) == scoreCategory {
            print("ScoreUP")
            score += 1
            scoreLabelNode.text = "Score:\(score)"
            
            var bestScore = userDefaults.integer(forKey: "BEST")
            if score > bestScore {
                bestScore = score
                bestScoreLabelNode.text = "Best Score\(bestScore)"
                userDefaults.set(bestScore, forKey: "BEST")
                userDefaults.synchronize()
            }
        } else if (contact.bodyA.categoryBitMask & itemScoreCategory) == itemScoreCategory || (contact.bodyB.categoryBitMask & itemScoreCategory) == itemScoreCategory {
                   print("ItemGet")
                   itemScore += 1
                   itemScoreLabelNode.text = "Item Score:\(itemScore)"
                   
            run(playSound)
            
//            itemPlayer?.play()
    
            if (contact.bodyA.categoryBitMask & itemScoreCategory) == itemScoreCategory {
                contact.bodyA.node?.removeFromParent()
            }
            if (contact.bodyB.categoryBitMask & itemScoreCategory) == itemScoreCategory {
                contact.bodyB.node?.removeFromParent()
                   }
        } else {
            print("GameOver")
            
            scrollNode.speed = 0
            
            bird.physicsBody?.collisionBitMask = groundCategory
            
            let roll = SKAction.rotate(byAngle: CGFloat(Double.pi) * CGFloat(bird.position.y) * 0.01 , duration: 1)
            bird.run(roll, completion:{
                self.bird.speed = 0
            })
        }
    }
    
    func restart() {
        score = 0
        scoreLabelNode.text = "Score:\(score)"
        
        itemScore = 0
        itemScoreLabelNode.text = String("Item Score:\(itemScore)")

        bird.position = CGPoint(x: self.frame.size.width * 0.2, y: self.frame.size.height * 0.7)
        bird.physicsBody?.velocity = CGVector.zero
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        bird.zRotation = 0

        wallNode.removeAllChildren()

        bird.speed = 1
        scrollNode.speed = 1
    }
    
    func setupScoreLabel() {
        score = 0
        scoreLabelNode = SKLabelNode()
        scoreLabelNode.fontColor = UIColor.black
        scoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 60)
        scoreLabelNode.zPosition = 100
        scoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        scoreLabelNode.text = "Score:\(score)"
        self.addChild(scoreLabelNode)
        
        bestScoreLabelNode = SKLabelNode()
        bestScoreLabelNode.fontColor = UIColor.black
        bestScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 90)
        bestScoreLabelNode.zPosition = 100
        bestScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        
        let bestScore = userDefaults.integer(forKey: "BEST")
        bestScoreLabelNode.text = "Best Score:\(bestScore)"
        self.addChild(bestScoreLabelNode)
        
        itemScore = 0
        itemScoreLabelNode = SKLabelNode()
        itemScoreLabelNode.fontColor = UIColor.black
        itemScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 120)
        itemScoreLabelNode.zPosition = 100
        itemScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        itemScoreLabelNode.text = "Score:\(itemScore)"
        self.addChild(itemScoreLabelNode)
        
    }
    
    func setupItem() {
        
        let itemTexture = SKTexture(imageNamed: "like_exist")
        itemTexture.filteringMode = .linear
        
        let movingDistance = CGFloat(self.frame.size.width * 2)
        
        let moveItem = SKAction.moveBy(x: -movingDistance, y: 0, duration: 4.0)
        
        let removeItem = SKAction.removeFromParent()
        
        let itemAnimation = SKAction.sequence(([moveItem, removeItem]))
        
        let createItemAnimation = SKAction.run ({
            
            let item = SKNode()
            item.position = CGPoint(x: self.frame.size.width + itemTexture.size().width / 2, y: 0.0)
            
            let center_y = self.frame.size.height / 2
            let ramdom_y_range = self.frame.size.height / 2
            let item_lowest_y = UInt32( center_y - itemTexture.size().height / 2 - ramdom_y_range / 2)
            let ramdom_y = arc4random_uniform( UInt32(ramdom_y_range))
            let item_y = CGFloat(item_lowest_y + ramdom_y)
            
            let center_x = self.frame.size.width / 2
            let ramdom_x_range = self.frame.size.width / 2
            let item_lowest_x = UInt32( center_x - itemTexture.size().width / 2 - ramdom_x_range / 2)
            let ramdom_x = arc4random_uniform( UInt32(ramdom_x_range))
            let item_x = CGFloat(item_lowest_x + ramdom_x)
            
            let itemSprite = SKSpriteNode(texture: itemTexture)
            itemSprite.position = CGPoint(x: item_x, y: item_y)
            
            itemSprite.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: itemSprite.size.width, height: itemSprite.size.height))
            itemSprite.physicsBody?.isDynamic = false
            itemSprite.physicsBody?.categoryBitMask = self.itemScoreCategory
            itemSprite.physicsBody?.contactTestBitMask = self.birdCategory
            
            item.addChild(itemSprite)
            
            item.run(itemAnimation)
            
            self.itemNode.addChild(item)
        })
        
        let waitAnimation = SKAction.wait(forDuration: 2)
        
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createItemAnimation, waitAnimation]))
        
        itemNode.run(repeatForeverAnimation)
        
    }
   }
        
//        func makingMoneyPositon() -> [CGPoint] {
//
//            let Xpos = [0.3, 0.4, 0.5, 0.6, 0.7]
//            let Ypos = [0.45, 0.55, 0.65, 0.75]
//
//            var moneyPositions: [CGPoint] = []
//            for y in Ypos {
//                for x in Xpos {
//                    let p = CGPoint(x: self.size.width * CGFloat(x), y: self.size.height * CGFloat(y))
//                    moneyPositions.append(p)
//                }
//            }
//
//            return moneyPositions
//        }
//
//        let moneyPositions = makingMoneyPositon()
//        let moneyTexture = SKTexture(imageNamed: "Money")
//
////        let texture = SKTexture(imageNamed: "money")
//
//        for i in 0...19 {
//            let money = makeMoney(moneyTexture: moneyTexture)
//            money.position = moneyPositions[i]
//            money.name = "money\(i)"
//            moneys[i] = (money, money.position, true)
//            self.addChild(money)
//        }
//      }
//
//    func makeMoney(moneyTexture: SKTexture) -> SKSpriteNode {
//        let money = SKSpriteNode(texture: moneyTexture)
//        money.physicsBody = SKPhysicsBody(texture: moneyTexture, size: moneyTexture.size())
//        money.physicsBody?.isDynamic = false
//        money.physicsBody?.isResting = true
//        money.physicsBody?.allowsRotation = true
//        money.physicsBody?.contactTestBitMask = 1
//        money.physicsBody?.restitution = 1.0
//        money.physicsBody?.friction = 1.0
//
////        let scaleUp = SKAction.scale(to: 0.5, duration: 0.5)
////        let scaleDw = SKAction.scale(to: 0.5, duration: 0.5)
////        let scaleUpDown = SKAction.sequence([scaleUp,scaleDw])
////        money.run(SKAction.repeatForever(scaleUpDown))
////
//        return money
//    }
//
//    func removeMoney() {
//    }
//
//    func appearMoney() {
//         let moneyTexture = SKTexture(imageNamed: "money")
//
//        for i in 0...19 {
//            if moneys[i]!.2 == false {
//                moneys[i]!.0 = makeMoney(moneyTexture: moneyTexture)
//                moneys[i]!.0.position = moneys[i]!.1
//                moneys[i]!.0.name = "money\(i)"
//
//                moneys[i]!.2 = true
//                self.addChild(moneys[i]!.0)
//                return
//            }
//        }
//    }
            
            
//        let groundSprite = SKSpriteNode(texture: groundTexture)
//
//        groundSprite.position = CGPoint(
//            x: groundTexture.size().width / 2,
//            y: groundTexture.size().height / 2
//        )
//
//        addChild(groundSprite)
