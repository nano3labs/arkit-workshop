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
  let button = UIButton(type: .system)
  let trackingStateLabel = UILabel()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    addSceneView()
    addTrackingStateLabel()
    addGestureRecognizers()
  }
  
  func addSceneView() {
    sceneView.delegate = self
    
    sceneView.showsStatistics = true
    
    let scene = SCNScene()
    scene.rootNode.addChildNode(moonNode)
    scene.physicsWorld.gravity = SCNVector3(0, -1.622, 0) // gravity on the moon = 1/6 * Earth's gravity, in m/s^2
    
    sceneView.scene = scene
    sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
    sceneView.automaticallyUpdatesLighting = true
    sceneView.isPlaying = true
    
  }
  
  var moonNode: SCNNode {
    var moonGeometry: SCNSphere {
      let moon = SCNSphere(radius: 0.2)
      moon.firstMaterial!.diffuse.contents = UIImage(named: "art.scnassets/moon.png")
      moon.firstMaterial!.normal.contents = UIImage(named: "art.scnassets/moon-normal")
      moon.firstMaterial!.normal.intensity = 3.0
      moon.firstMaterial!.lightingModel = .physicallyBased
      return moon
    }
    
    let moon = SCNNode(geometry: moonGeometry)
    moon.name = "Moon"
    moon.position = SCNVector3(0, 0, -0.8)
    moon.physicsBody = SCNPhysicsBody.kinematic()
    
    var rotationOnRepeat: SCNAction {
      let rotationAction = SCNAction.rotateBy(x: 0, y: 2 * .pi, z: 0, duration: 15.0)
      let repeatAction = SCNAction.repeatForever(rotationAction)
      return repeatAction
    }
    
    moon.runAction(rotationOnRepeat)
    return moon
  }
  
  func addTrackingStateLabel() {
    trackingStateLabel.frame = CGRect(x: view.frame.width / 2 - (200 / 2), y: 50, width: 200, height: 100)
    trackingStateLabel.numberOfLines = 2
    trackingStateLabel.text = "Learning about surrounding... Try moving camera around"
    sceneView.addSubview(trackingStateLabel)
  }
  
  func addGestureRecognizers() {
    let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
    view.addGestureRecognizer(tapGestureRecognizer)
    // view refers to the sceneView instance
    let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
    view.addGestureRecognizer(panGestureRecognizer)
  }
  
  
  
  @objc func handleTap(gesture: UITapGestureRecognizer) {
    let location = gesture.location(in: view)
    
    let hitResult = sceneView.hitTest(location, types: .existingPlaneUsingExtent)
    
    if let hitPoint = hitResult.first {
      
      let x = hitPoint.worldTransform.columns.3.x
      let y = hitPoint.worldTransform.columns.3.y
      let z = hitPoint.worldTransform.columns.3.z
      
      let apolloNode = newApolloNode()
      apolloNode.position = SCNVector3(x, y + 1.59282, z)
      
      sceneView.scene.rootNode.addChildNode(apolloNode)
    }
  }
  
  
  var apolloModel: SCNNode {
    let apolloScene = SCNScene(named: "art.scnassets/apollo-11.scn")!
    let apollo = apolloScene.rootNode.childNode(withName: "apollo-11", recursively: false)!
    apollo.scale = SCNVector3(0.00034, 0.00034, 0.00034)
    apollo.rotation = SCNVector4(0, 1, 0, CGFloat.pi / 2)
    
    let fire = SCNParticleSystem(named: "art.scnassets/fire.scnp", inDirectory: "/")!
    let emitter = apollo.childNode(withName: "emitter", recursively: true)!
    emitter.addParticleSystem(fire)
    
    return apollo
  }
  
  func newApolloNode() -> SCNNode {
    let apolloNode = SCNNode()
    let collider = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0)
    apolloNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(geometry: collider, options: nil))
    apolloNode.physicsBody?.mass = 1.0
    apolloNode.physicsBody?.restitution = 0.0
    apolloNode.physicsBody?.friction = 1.0
    apolloNode.addChildNode(apolloModel)
    
    return apolloNode
  }
  
  var selectedNode:SCNNode?
  
  @objc func handlePan(gesture: UIPanGestureRecognizer) {
    let location = gesture.location(in: view)
    
    switch gesture.state {
    case .began: // choose which object to move
      let objectsHit = sceneView.hitTest(location, options: nil)
      
      if let firstObject = objectsHit.first,
        firstObject.node.name == "apollo-11" {
        selectedNode = firstObject.node
      }
    case .changed: // move the chosen object
      guard let m = selectedNode else { return }
      let hitResult = sceneView.hitTest(location, types: .existingPlaneUsingExtent)
      if let hitPoint = hitResult.first {
        let x = hitPoint.worldTransform.columns.3.x
        let y = hitPoint.worldTransform.columns.3.y + 0.098
        let z = hitPoint.worldTransform.columns.3.z
        
        m.parent!.worldPosition = SCNVector3(x, y, z)
      }
    default:
      selectedNode = nil
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
