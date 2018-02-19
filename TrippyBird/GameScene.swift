//
//  GameScene.swift
//  TrippyBird
//
//  Created by nsp on 1/10/2014.
//  Copyright (c) 2014 nspool. All rights reserved.
//

import SpriteKit
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}


class GameScene: SKScene, SKPhysicsContactDelegate {
  
  var _bird: SKSpriteNode!
  var _skyColor: SKColor!
  let kVerticalPipeGap: CGFloat = 200.0
  let pipeTexture1: SKTexture = SKTexture(imageNamed: "Pipe1")
  let pipeTexture2: SKTexture = SKTexture(imageNamed: "Pipe2")
  var _moveAndRemovePipes: SKAction!
  let _moving: SKNode = SKNode()
  let _pipes: SKNode = SKNode()
  var _canRestart: Bool = false
  let _scoreLabelNode: SKLabelNode = SKLabelNode(fontNamed: "MarkerFelt-Wide")
  var _score: NSInteger = 0
  
  // categories to determine what has been collided with.
  let birdCategory: UInt32 = 1 << 0;
  let worldCategory: UInt32 = 1 << 1;
  let pipeCategory: UInt32 = 1 << 2;
  let scoreCategory: UInt32 = 1 << 3;
  
  func spawnPipes() {
    // pipe pair
    let pipePair: SKNode = SKNode()
    pipePair.position = CGPoint( x: self.frame.size.width, y: 0 );
    
    // random position of the gap between the pipes
    let y = CGFloat(arc4random() % (UInt32)( self.frame.size.height / 3 ))
    
    let pipe1: SKSpriteNode = SKSpriteNode(texture: pipeTexture1)
    pipe1.setScale(4)
    pipe1.position = CGPoint( x: 0, y: y );
    pipe1.physicsBody = SKPhysicsBody(rectangleOf: pipe1.size)
    pipe1.physicsBody!.isDynamic = false;
    pipePair.addChild(pipe1)
    
    let pipe2: SKSpriteNode = SKSpriteNode(texture: pipeTexture2)
    pipe2.setScale(4)
    pipe2.position = CGPoint( x: 0, y: y + pipe1.size.height + kVerticalPipeGap );
    pipe2.physicsBody = SKPhysicsBody(rectangleOf: pipe2.size)
    pipe2.physicsBody!.isDynamic = false;
    pipePair.addChild(pipe2)
    
    let contactNode: SKNode = SKNode()
    contactNode.position = CGPoint( x: pipe1.size.width + _bird.size.width / 2, y: self.frame.midY );
    contactNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize( width: pipe2.size.width, height: self.frame.size.height ))
    contactNode.physicsBody!.isDynamic = false;
    contactNode.physicsBody!.categoryBitMask = scoreCategory;
    contactNode.physicsBody!.contactTestBitMask = birdCategory;
    pipePair.addChild(contactNode)
    
    // pipe movement
    pipePair.run(_moveAndRemovePipes)
    _pipes.addChild(pipePair)
    
  }
  
  override func didMove(to view: SKView) {
    // set the sky colour
    _skyColor = SKColor(red: 113.0/255.0, green: 197.0/255.0, blue: 207.0/255.0, alpha: 1.0)
    self.backgroundColor = _skyColor
    // create the textures
    let birdTexture1: SKTexture = SKTexture(imageNamed: "Bird1")
    let birdTexture2: SKTexture = SKTexture(imageNamed: "Bird2")
    let groundTexture: SKTexture = SKTexture(imageNamed:"Ground")
    let skylineTexture: SKTexture = SKTexture(imageNamed:"Skyline")
    birdTexture1.filteringMode = SKTextureFilteringMode.nearest
    birdTexture2.filteringMode = SKTextureFilteringMode.nearest
    pipeTexture1.filteringMode = SKTextureFilteringMode.nearest
    pipeTexture2.filteringMode = SKTextureFilteringMode.nearest
    groundTexture.filteringMode = SKTextureFilteringMode.nearest
    skylineTexture.filteringMode = SKTextureFilteringMode.nearest
    
    // set |moving| as the parent node so we can stop everything easily
    self.addChild(_moving)
    _moving.addChild(_pipes)
    
    // flap
    let flap: SKAction = SKAction.repeatForever(SKAction.animate(with: [birdTexture1,birdTexture2], timePerFrame: 0.2))
    
    // create a new node and apply the texture to it
    _bird = SKSpriteNode(texture: birdTexture1)
    _bird.setScale(4)
    _bird.position = CGPoint(x: self.frame.size.width/2, y: self.frame.midY)
    _bird.run(flap)
    
    // physics
    self.physicsWorld.gravity = CGVector( dx: 0.0, dy: -5.0 );
    
    self.physicsWorld.contactDelegate = self;
    
    // physics: falling bird
    _bird.physicsBody = SKPhysicsBody(circleOfRadius: _bird.size.height / 2);
    _bird.physicsBody?.isDynamic = true;
    _bird.physicsBody?.allowsRotation = false;
    
    // make sure we get notified if the bird has collided into either the ground or the pip
    _bird.physicsBody?.categoryBitMask = birdCategory;
    _bird.physicsBody?.collisionBitMask = worldCategory | pipeCategory;
    _bird.physicsBody?.contactTestBitMask = worldCategory | pipeCategory;
    
    // physics: ground
    let groundBody: SKNode = SKNode()
    groundBody.position = CGPoint(x: 0, y: groundTexture.size().height)
    groundBody.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: self.frame.size.width, height: groundTexture.size().height * 2))
    groundBody.physicsBody?.isDynamic = false
    
    self.addChild(groundBody)
    
    /* add the sprites */
    
    // parallax effect: ground
    let moveGroundSprite: SKAction = SKAction.moveBy(x: -groundTexture.size().width * 2, y: 0, duration: TimeInterval(0.02 * groundTexture.size().width * 2.0))
    let resetGroundSprite: SKAction = SKAction.moveBy(x: groundTexture.size().width*2, y: 0.0, duration: 0)
    let moveGroundSpritesForever: SKAction = SKAction.repeatForever(SKAction.sequence([moveGroundSprite,resetGroundSprite]))
    
    // parallax effect: skyline
    let moveSkylineSprite: SKAction = SKAction.moveBy(x: -skylineTexture.size().width*2, y: 0.0, duration: TimeInterval(0.1 * skylineTexture.size().width * 2.0))
    let resetSkylineSprite: SKAction = SKAction.moveBy(x: skylineTexture.size().width*2, y: 0.0, duration: 0)
    let moveSkylineSpritesForever: SKAction = SKAction.repeatForever(SKAction.sequence([moveSkylineSprite,resetSkylineSprite]))
    
    // ground & skyline
    
    let limit: Int = 2 + Int(self.frame.size.width / ( groundTexture.size().width * 2 ));
    for i in 0 ..< limit {
      let ground: SKSpriteNode = SKSpriteNode(texture: groundTexture)
      ground.setScale(4.0)
      ground.position = CGPoint(x: CGFloat(i) * ground.size.width, y: ground.size.height / 2);
      ground.run(moveGroundSpritesForever)
      
      let skyline: SKSpriteNode = SKSpriteNode(texture: skylineTexture)
      skyline.setScale(4.0)
      skyline.position = CGPoint(x: CGFloat(i) * skyline.size.width, y: skyline.size.height / 2 + groundTexture.size().height * 2);
      skyline.run(moveSkylineSpritesForever)
      
      _moving.addChild(ground)
      _moving.addChild(skyline)
    }
    
    let distanceToMove:CGFloat = self.frame.size.width + 2 * pipeTexture1.size().width;
    let movePipes:SKAction = SKAction.moveBy(x: -distanceToMove, y: 0.0, duration: TimeInterval(0.01 * distanceToMove))
    let removePipes: SKAction = SKAction.removeFromParent()
    _moveAndRemovePipes = SKAction.sequence([movePipes, removePipes])
    
    self.run(SKAction.repeatForever(SKAction.sequence([SKAction.run(self.spawnPipes), SKAction.wait(forDuration: 3)])))
    
    // flappy
    self.addChild(_bird)
    
    // scoreboard
    _scoreLabelNode.position = CGPoint( x: self.frame.midX, y: 3 * self.frame.size.height / 4 );
    _scoreLabelNode.zPosition = 100;
    _scoreLabelNode.text = "\(_score)";
    self.addChild(_scoreLabelNode)
  }
  
  func didBegin(_ contact: SKPhysicsContact) {
    if(_moving.speed > 0 ) {
      if(contact.bodyA.categoryBitMask == scoreCategory || contact.bodyB.categoryBitMask == scoreCategory) {
        _score += 1;
        _scoreLabelNode.text = "\(_score)";
        _scoreLabelNode.run(SKAction.sequence([SKAction.scale(to: 2, duration: TimeInterval(0.1)), SKAction.scale(to: 1.0, duration: TimeInterval(0.1))]))
      } else {
        _moving.speed = 0;
        
        _bird.physicsBody?.collisionBitMask = worldCategory;
        
        let rotateBirdRadians: CGFloat = .pi * _bird.position.y * 0.01
        let rotateBirdDuration: TimeInterval = TimeInterval(_bird.position.y * 0.003)
        let rotateBird: SKAction = SKAction.rotate(byAngle: rotateBirdRadians, duration: rotateBirdDuration)
        _bird.run(rotateBird, completion:{
          self._bird.speed = 0
        })
        
        self.removeAction(forKey: "flash")
        self.run(SKAction.sequence([SKAction.repeat(SKAction.sequence([SKAction.run({
          self.backgroundColor = SKColor.red
        }),SKAction.wait(forDuration: 0.05),SKAction.run({
          self.backgroundColor = self._skyColor
        }),SKAction.wait(forDuration: 0.05)]), count: 4)]), withKey:"flash")
        self._canRestart = true;
      }
    }
  }
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    if(_moving.speed > 0 ) {
      _bird.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
      _bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 32))
    }
    if(self._canRestart) {
      self.resetScene()
    }
  }
  
  func resetScene() {
    
    // Move bird to original position and reset velocity
    _bird.position = CGPoint(x: self.frame.size.width/2, y: self.frame.midY)
    _bird.physicsBody?.velocity = CGVector( dx: 0, dy: 0 );
    _bird.physicsBody?.collisionBitMask = worldCategory | pipeCategory;
    _bird.speed = 1.0;
    _bird.zRotation = 0.0;
    
    _pipes.removeAllChildren()
    _canRestart = false;
    _moving.speed = 1;
    _score = 0
    _scoreLabelNode.text = "\(_score)";
  }
  
  func clamp(_ min: CGFloat, max: CGFloat, value:CGFloat)->CGFloat {
    if( value > max ) {
      return max;
    } else if( value < min ) {
      return min;
    } else {
      return value;
    }
  }
  
  override func update(_ currentTime: TimeInterval) {
    if( _moving.speed > 0 ) {
      _bird.zRotation = clamp(-1, max:0.5, value:_bird.physicsBody!.velocity.dy * ( _bird.physicsBody?.velocity.dy < 0 ? 0.003 : 0.001 ))
    }
  }
}
