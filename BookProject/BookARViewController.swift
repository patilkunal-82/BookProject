//
//  ARViewController.swift
//  BookProject
//
//  Created by Kunal Patil on 1/4/21.
//

import UIKit
import ARKit

class BookARViewController: ViewController, ARSCNViewDelegate {

    let sceneView = ARSCNView()
    var bookAnchorContentNames: [String : [String]] = [:] {
        didSet {
            print("bookAnchorContentNames: \(bookAnchorContentNames)")
        }
    }
    private var anchorsAndContentData: [ARReferenceImage : [UIImage]] = [:]
    private let fileManager = FileManager()

    var bookDirectoryPath: String = ""
    override func viewDidLoad() {
        super.viewDidLoad()

        sceneView.frame = view.bounds
        view.addSubview(sceneView)
        
        // Set the view's delegate
        sceneView.delegate = self

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
        let imageNode = ImagesContainerPlaneNode(images: contentArray)
        node.addChildNode(imageNode)
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
            guard let image = getImageAtBookDirectory(byName: anchor) else { continue }
            
            guard let imageToCIImage = CIImage(image: image), let cgImage = convertCIImageToCGImage(inputImage: imageToCIImage) else {
                print("Can not convert UIImage to CGIImage \(anchor)")
                continue
            }

            let arImage = ARReferenceImage(cgImage, orientation: CGImagePropertyOrientation.up, physicalWidth: 0.2)
            
            anchorsAndContentData[arImage] = []
            for content in bookAnchorContentNames[anchor]! {
                guard let contentImage = getImageAtBookDirectory(byName: content) else { continue }
                anchorsAndContentData[arImage]?.append(contentImage)
            }
        }
    }
    
    private func getImageAtBookDirectory(byName imageName: String) -> UIImage? {
        let path = bookDirectoryPath.appending("/" + imageName)
        guard fileManager.fileExists(atPath: path), let image = UIImage(contentsOfFile: path) else {
            print("file does not exist \(path) or can't read file into UIImage")
            return nil
        }
        return image
    }
}
