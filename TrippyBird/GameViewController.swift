//
//  GameViewController.swift
//  TrippyBird
//
//  Created by nsp on 1/10/2014.
//  Copyright (c) 2014 nspool. All rights reserved.
//

import UIKit
import SpriteKit

class GameViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    
    if let scene = GameScene.unarchiveFromFile("GameScene") as? GameScene {
      
      // Configure the view.
      let skView = self.view as! SKView
      skView.showsFPS = true
      skView.showsNodeCount = true
      
      /* Sprite Kit applies additional optimizations to improve rendering performance */
      skView.ignoresSiblingOrder = true
      
      /* Set the scale mode to scale to fit the window */
      scene.scaleMode = .aspectFill
      
      skView.presentScene(scene)
    }
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Release any cached data, images, etc that aren't in use.
  }
  
}

// Mark: Extension
extension SKNode {
  class func unarchiveFromFile(_ file : NSString) -> SKNode? {
    if let path = Bundle.main.path(forResource: file as String, ofType: "sks") {
      var sceneData: Data?
      do {
        sceneData = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
      } catch _ {
        sceneData = nil
      }
      let archiver = NSKeyedUnarchiver(forReadingWith: sceneData!)
      
      archiver.setClass(self.classForKeyedUnarchiver(), forClassName: "SKScene")
      let scene = archiver.decodeObject(forKey: NSKeyedArchiveRootObjectKey) as! GameScene
      archiver.finishDecoding()
      return scene
    } else {
      return nil
    }
  }
}
