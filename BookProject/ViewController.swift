//
//  ViewController.swift
//  BookProject
//
//  Created by Kunal Patil on 10/13/20.
//

import UIKit
import SceneKit
import ARKit



class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
   // @IBOutlet weak var cancelButton: UIButton!
    
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var anchorInstruction: UILabel!
    
    @IBOutlet weak var swipeInstruction: UILabel!
    
    
    @IBOutlet weak var exploreMore: UIButton!
    
    
    /// Source for audio playback
    var audioSource: SCNAudioSource!

    var planeNode: SCNNode?
    var node: SCNNode?
    var nodeFirst: SCNNode?
    var nodeSecond: SCNNode?
    var background: SCNMaterialProperty?
    var imageView: UIImageView?
    private var index: Int = 1
    var listIndex: Int = -1
    let path = Bundle.main.path(forResource: "ImageList", ofType: "plist")
    var dict: NSDictionary?
    let configuration = ARWorldTrackingConfiguration()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Set up audio playback
        setUpAudio()
        
        // Enable swipe gesture
       let swipeGesture = UISwipeGestureRecognizer(target: self, action:#selector(didSwipe(_:)))
        sceneView.addGestureRecognizer(swipeGesture)
        
        dict = NSDictionary(contentsOfFile: path!)
        swipeInstruction.isHidden  = true
        exploreMore.isHidden = true
    }
    
    
    @IBAction func exploreMoreClicked(_ sender: Any) {
        
        guard let anchors = sceneView.session.currentFrame?.anchors else {return}
        for anchor in anchors{
            if let myUrlAnchor = anchor as? ARImageAnchor{
                if myUrlAnchor.name == "cars" {
                    let url = URL(string: "https://www.edmunds.com")!
                    UIApplication.shared.open(url)
                }
                if myUrlAnchor.name == "flowers" {
                    let url = URL(string: "https://www.all-my-favourite-flower-names.com")!
                    UIApplication.shared.open(url)
                }
                if myUrlAnchor.name == "mountain" {
                    let url = URL(string: "https://www.treebo.com")!
                    UIApplication.shared.open(url)
                } else {
                    let url = URL(string: "https://www.google.com")!
                    UIApplication.shared.open(url)
                }
                
            }
        }
    }
    
    @IBAction func cancelButtonCliked(_ sender: Any) {
        
        sceneView.session.pause()
        sceneView.scene.rootNode.enumerateChildNodes{ (node,SSTOP) in
            node.removeFromParentNode()
        }
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        anchorInstruction.isHidden = false
        swipeInstruction.isHidden = true
        exploreMore.isHidden = true
       
        
    }
   
    @objc
    func didSwipe(_ gesture:UISwipeGestureRecognizer){
        if gesture.state == .ended {
        addItemfromList()
        //addItem()
        }
        
    }
   
    func addItemfromList () {
        
        self.exploreMore.isHidden = false
        guard let anchors = sceneView.session.currentFrame?.anchors, let dictionary = dict else { return }
        for anchor in anchors {
            if let myImageAnchor = anchor as? ARImageAnchor {
                
                let imageArray = dictionary[myImageAnchor.name!] as! [String]
                
                DispatchQueue.main.async { [self] in
                    
                    self.listIndex = listIndex + 1
                    let node = SCNNode()
                    node.geometry = SCNPlane(width: 0.2, height: 0.2)

                    if listIndex >= imageArray.count {
                        listIndex = imageArray.count - 1
                    }
                    node.geometry?.firstMaterial?.diffuse.contents = UIImage(named: imageArray[listIndex])
                    
                    node.geometry?.firstMaterial?.locksAmbientWithDiffuse = true
                    
                    self.sceneView.scene.rootNode.replaceChildNode(self.planeNode!, with: node)
                    self.planeNode = node
                
                    if listIndex >= imageArray.count - 1 {
                        listIndex = -1
                    }
                }
            }
        }
            
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        guard let referenceImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: nil) else {
                   fatalError("Missing expected asset catalog resources.")
        }
       // let configuration = ARWorldTrackingConfiguration()
            configuration.detectionImages = referenceImages
            
        // Run the view's session
        sceneView.session.run(configuration)
        
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let imageAnchor = anchor as? ARImageAnchor else {
            return
        }
        
        let planeScene = SCNScene(named: "art.scnassets/1.scn")!
        planeNode = planeScene.rootNode.childNode(withName: "toy_biplane", recursively: true)!
        let pos = imageAnchor.transform.columns.3
        planeNode?.isHidden = true
        planeNode!.simdPosition = simd_float3(pos.x, pos.y, pos.z)
        planeNode!.addAudioPlayer(SCNAudioPlayer(source:audioSource))
        sceneView.scene.rootNode.addChildNode(planeNode!)
        sceneView.backgroundColor = .black
        
        DispatchQueue.main.async {
            self.anchorInstruction.isHidden = true
            
            self.swipeInstruction.isHidden = false
            
        }
        
        
        
        
        
    }
    
    
   /* An SCNAudioPlayer object controls playback of a positional audio source in a SceneKit scene. To use positional audio, first create a reusable SCNAudioSource or AVAudioNode object to provide an audio stream. Then, create an audio player to control the playback of that audio source. Finally, attach the audio player to an SCNNode object for spatialized 3D audio playback based on the position of that node relative to the scene’s audioListener node.*/
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        
      let player = planeNode?.audioPlayers.first
      let avNode = player?.audioNode as? AVAudioMixing
        
        if let pointOfView = sceneView.pointOfView, let plane = planeNode {
            if !sceneView.isNode(plane, insideFrustumOf: pointOfView) {
                avNode?.volume = 0.0
                print("volume 0")
            } else {
                avNode?.volume = 1.0
                print("volume 1")
            }
        }
    }

    private func setUpAudio() {
           // Instantiate the audio source
           audioSource = SCNAudioSource(fileNamed: "fireplace.mp3")!
           // As an environmental sound layer, audio should play indefinitely
           audioSource.loops = true
           // Decode the audio from disk ahead of time to prevent a delay in playback
           audioSource.load()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.scene.rootNode.removeAllAudioPlayers()
        // Pause the view's session
        sceneView.session.pause()
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
}
