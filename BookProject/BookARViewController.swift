//
//  ARViewController.swift
//  BookProject
//
//  Created by Kunal Patil on 1/4/21.
//

import UIKit
import ARKit
import AVFoundation
import AVKit


enum ContentType {
    case image
    case video
    case model3D
}

struct AssetContainer {
    let type: ContentType
    let image: UIImage?
    var video: AVPlayer?
    //var model: Model3D?
}

class BookARViewController: ViewController, ARSCNViewDelegate {

    let sceneView = ARSCNView()
    var bookAnchorContentNames: [String : [String]] = [:] {
        didSet {
            print("bookAnchorContentNames: \(bookAnchorContentNames)")
        }
    }
    private var anchorsAndContentData: [ARReferenceImage : [AssetContainer]] = [:]
  //  private var anchorsAndContentData: [ARReferenceImage : [UIImage]] = [:]
    private let fileManager = FileManager()

    var bookDirectoryPath: String = ""
    override func viewDidLoad() {
        super.viewDidLoad()

        sceneView.frame = view.bounds
        view.addSubview(sceneView)
        
        // Set the view's delegate
        sceneView.delegate = self
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
        }
        catch {
            print("Setting category to AVAudioSessionCategoryPlayback failed.")
        }

        // Show statistics such as fps and timing information
//        sceneView.showsStatistics = true
        let tapGesture = UITapGestureRecognizer(target: self, action:#selector(didTap(_:)))
        sceneView.addGestureRecognizer(tapGesture)
        
    }
        
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        prepareAnchorsAndContentData()
        // Create a session configuration
        guard anchorsAndContentData.keys.count > 0 else {
            fatalError("No anchors found")
        }
        let configuration = ARWorldTrackingConfiguration()
        configuration.detectionImages = Set(anchorsAndContentData.keys)

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
       super.viewWillDisappear(animated)
       // Pause the view's session
       sceneView.session.pause()
   }
    
    @objc
    func didTap(_ gesture:UISwipeGestureRecognizer) {
        // hittest
        guard let result = sceneView.hitTest(gesture.location(in: sceneView), options: nil).first, let imageNode = result.node as? ImagesContainerPlaneNode else { return }
        imageNode.showNextImage()
    }
}

//Mark:- ARSCNViewDelegate
extension BookARViewController {
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let imageAnchor = anchor as? ARImageAnchor else { return }
        guard let contentArray = anchorsAndContentData[imageAnchor.referenceImage] else {
            print("no content found for anchor: \(String(describing: imageAnchor.name))")
            return
        }
        
    //let imageNode = ImagesContainerPlaneNode(images: contentArray)
    //node.addChildNode(imageNode)
       
       let displayNode = ImagesContainerPlaneNode (mixedContent: contentArray)
        node.addChildNode(displayNode)
        
    }
}

//Mark:- file access
extension BookARViewController {
    private func convertCIImageToCGImage(inputImage: CIImage) -> CGImage? {
        let context = CIContext(options: nil)
        if let cgImage = context.createCGImage(inputImage, from: inputImage.extent) {
         return cgImage
        }
        return nil
    }
    
    private func prepareAnchorsAndContentData() {
        for anchor in bookAnchorContentNames.keys {
            guard let image = getImageAtBookDirectory(atPath: bookDirectoryPath.appending("/" + anchor)) else { continue }
            
            guard let imageToCIImage = CIImage(image: image), let cgImage = convertCIImageToCGImage(inputImage: imageToCIImage) else {
                print("Can not convert UIImage to CGIImage \(anchor)")
                continue
            }

            let arImage = ARReferenceImage(cgImage, orientation: CGImagePropertyOrientation.up, physicalWidth: 0.2)
            
            anchorsAndContentData[arImage] = []
            
            
            for content in bookAnchorContentNames[anchor]! {
                let path = bookDirectoryPath.appending("/" + content)
                let url = URL(fileURLWithPath: path)
                let pathExtension = url.pathExtension
                // check the path extension
                
                if  pathExtension == "jpg" {
                guard let contentImage = getImageAtBookDirectory(atPath: path) else { continue }
                let assetContainer = AssetContainer(type: .image, image: contentImage)
                anchorsAndContentData[arImage]?.append(assetContainer)
                }

                if pathExtension == "mp4" {
                guard let contentVideo = getVideoAtBookDirectory(atPath: path) else { continue }
               // let videoContentController = AVPlayerViewController()
              //  videoContentController.player = contentVideo
                let assetContainer = AssetContainer(type: .video, image: image, video: contentVideo)
                anchorsAndContentData[arImage]?.append(assetContainer)
                }
            }
        }
    }
    
    private func getImageAtBookDirectory(atPath path: String) -> UIImage? {
        guard fileManager.fileExists(atPath: path), let image = UIImage(contentsOfFile: path) else {
            print("file does not exist \(path) or can't read file into UIImage")
            return nil
        }
        return image
    }
    
    private func getVideoAtBookDirectory(atPath path: String) -> AVPlayer? {
        let videoURL = URL(fileURLWithPath: path)
        let video = AVPlayer(url: videoURL)
        //let videoController = AVPlayerViewController()
        guard fileManager.fileExists(atPath: path)  else {
            print("file does not exist \(path) or can't read file into UIImage")
            return nil
        }
        return video
    }
}
