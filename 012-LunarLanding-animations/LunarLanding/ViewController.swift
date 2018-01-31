//
//  ViewController.swift
//  LunarLanding
//
//  Created by Michael Yagudaev on 2018-01-20.
//  Copyright © 2018 Michael Yagudaev. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
  
  @IBOutlet var sceneView: ARSCNView!
  var anchorCount = 0
  var moonNode = SCNNode()
  let button = UIButton(type: .system)
  let trackingStateLabel = UILabel()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Set the view's delegate
    sceneView.delegate = self
    
    // Show statistics such as fps and timing information
    sceneView.showsStatistics = true
    
    // Create a new scene
    // let scene = SCNScene(named: "art.scnassets/ship.scn")!
    let scene = SCNScene()
    
    let moon = SCNSphere(radius: 0.2)
    moon.firstMaterial!.diffuse.contents = UIImage(named: "art.scnassets/moon.png")
    moon.firstMaterial!.normal.contents = UIImage(named: "art.scnassets/moon-normal")
    moon.firstMaterial!.normal.intensity = 3.0
    moon.firstMaterial!.lightingModel = .physicallyBased
    moonNode = SCNNode(geometry: moon)
    moonNode.name = "Moon"
    moonNode.position = SCNVector3(0, 0, -0.8)
    moonNode.physicsBody = SCNPhysicsBody.kinematic()
    
    let rotationAction = SCNAction.rotateBy(x: 0, y: 2 * .pi, z: 0, duration: 15.0)
    let repeatAction = SCNAction.repeatForever(rotationAction)
    moonNode.runAction(repeatAction)
    
    scene.rootNode.addChildNode(moonNode)
    
    // Set the scene to the view
    sceneView.scene = scene
    scene.physicsWorld.gravity = SCNVector3(0, -1.622, 0)
    sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
    sceneView.automaticallyUpdatesLighting = true
    
    trackingStateLabel.frame = CGRect(x: view.frame.width / 2 - (200 / 2), y: 50, width: 200, height: 100)
    trackingStateLabel.numberOfLines = 2
    trackingStateLabel.text = "Learning about surrounding... Try moving camera around"
    sceneView.addSubview(trackingStateLabel)
    sceneView.isPlaying = true
    
    addGestureRecognizers()
  }
  
  func addGestureRecognizers() {
    let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
    view.addGestureRecognizer(tapGestureRecognizer)
    
    let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
    view.addGestureRecognizer(panGestureRecognizer)
  }
  
  var selectedNode:SCNNode? = nil
  @objc func handlePan(gesture: UIPanGestureRecognizer) {
    let location = gesture.location(in: view)
    
    if (gesture.state == .began) {
      let objectsHit = sceneView.hitTest(location, options: nil)
      
      if let objectHit = objectsHit.first {
        if objectHit.node.name == "apollo-11" {
          selectedNode = objectHit.node
        } else {
          selectedNode = nil
        }
      }
    } else if (gesture.state == .changed) {
      guard let m = selectedNode else { return }
      let hitResult = sceneView.hitTest(location, types: .existingPlaneUsingExtent)
      if let hitPoint = hitResult.first {
        let x = hitPoint.worldTransform.columns.3.x
        let y = hitPoint.worldTransform.columns.3.y + 0.098
        let z = hitPoint.worldTransform.columns.3.z
        
        m.parent!.worldPosition = SCNVector3(x, y, z)
      } else if (gesture.state == .ended || gesture.state == .cancelled || gesture.state == .failed) {
        selectedNode = nil
      }
    }
  }
  
  @objc func handleTap(gesture: UITapGestureRecognizer) {
    let location = gesture.location(in: view)
    
    let hitResult = sceneView.hitTest(location, types: .existingPlaneUsingExtent)
    
    if let hitPoint = hitResult.first {
      let x = hitPoint.worldTransform.columns.3.x
      let y = hitPoint.worldTransform.columns.3.y
      let z = hitPoint.worldTransform.columns.3.z
      
      let apolloScene = SCNScene(named: "art.scnassets/apollo-11.scn")!
      let apollo = apolloScene.rootNode.childNode(withName: "apollo-11", recursively: false)!
      apollo.scale = SCNVector3(0.00034, 0.00034, 0.00034)
      apollo.rotation = SCNVector4(0, 1, 0, CGFloat.pi / 2)
      let apolloNode = SCNNode()
      
      
//      apolloNode.position = SCNVector3(x, y + 0.09282, z)
      apolloNode.position = SCNVector3(x, y + 1.59282, z)
      
      let collider = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0)
      apolloNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(geometry: collider, options: nil))
      apolloNode.physicsBody?.mass = 1.0
      apolloNode.physicsBody?.restitution = 0.0
      apolloNode.physicsBody?.friction = 1.0
      
      apolloNode.addChildNode(apollo)
      
      let fire = SCNParticleSystem(named: "art.scnassets/fire.scnp", inDirectory: "/")!
      let emitter = apollo.childNode(withName: "emitter", recursively: true)!
      emitter.addParticleSystem(fire)
      
      sceneView.scene.rootNode.addChildNode(apolloNode)
    }
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    // Create a session configuration
    let configuration = ARWorldTrackingConfiguration()
    configuration.isLightEstimationEnabled = true
    configuration.planeDetection = .horizontal
    
    // Run the view's session
    sceneView.session.run(configuration)
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    
    // Pause the view's session
    sceneView.session.pause()
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Release any cached data, images, etc that aren't in use.
  }
  
  // MARK: - ARSCNViewDelegate
  
  /*
   // Override to create and configure nodes for anchors added to the view's session.
   func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
   let node = SCNNode()
   
   return node
   }
   */
  
  func session(_ session: ARSession, didFailWithError error: Error) {
    // Present an error message to the user
    
  }
  
  func sessionWasInterrupted(_ session: ARSession) {
    // Inform the user that the session has been interrupted, for example, by presenting an overlay
    
  }
  
  func sessionInterruptionEnded(_ session: ARSession) {
    // Reset tracking and/or remove existing anchors if consistent tracking is required
    
  }
  
  func session(_ session: ARSession, didUpdate frame: ARFrame) {
    
  }
  
  func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
    
    switch(camera.trackingState) {
    case .notAvailable:
      trackingStateLabel.text = "Cannot start ARSession!"
      
    case .limited(.initializing):
      trackingStateLabel.text = "Learning about surrounding. Try moving around"
    case .limited(.insufficientFeatures):
      trackingStateLabel.text = "Try turning on more lights and moving around"
    case .limited(.excessiveMotion):
      trackingStateLabel.text = "Try moving your phone slower"
      
    case .normal:
      trackingStateLabel.text = ""
    }
  }
  
  func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
    guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
    
    let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
    let planeMaterial = SCNMaterial()
    planeMaterial.diffuse.contents = UIImage(named: "art.scnassets/moon.png")!
    planeMaterial.normal.contents = UIImage(named: "art.scnassets/moon-normal.png")!
    planeMaterial.lightingModel = .physicallyBased
    plane.firstMaterial = planeMaterial
    
    let planeNode = SCNNode(geometry: plane)
    planeNode.position = SCNVector3(planeAnchor.center.x, 0, planeAnchor.center.y)
    planeNode.eulerAngles.x = -.pi / 2
    planeNode.physicsBody = SCNPhysicsBody.static()
    node.addChildNode(planeNode)
  }
  
  func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
    guard let planeAnchor = anchor as? ARPlaneAnchor,
      let planeNode = node.childNodes.first,
      let plane = planeNode.geometry as? SCNPlane
      else { return }
    
    planeNode.position = SCNVector3(planeAnchor.center.x, 0, planeAnchor.center.z)
    plane.width = CGFloat(planeAnchor.extent.x)
    plane.height = CGFloat(planeAnchor.extent.z)
    
    planeNode.physicsBody?.physicsShape = SCNPhysicsShape()
  }
}

