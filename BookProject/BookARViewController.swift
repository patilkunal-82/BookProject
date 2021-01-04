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
    var bookDirectoryPath: String = ""
    override func viewDidLoad() {
        super.viewDidLoad()

        sceneView.frame = view.bounds
        view.addSubview(sceneView)
        
        // Set the view's delegate
        sceneView.delegate = self

        // Show statistics such as fps and timing information
//        sceneView.showsStatistics = true
    }
        
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let arAnchors = getARAnchors()
        // Create a session configuration
        guard arAnchors.count > 0 else {
            fatalError("No anchors found")
        }
        let configuration = ARWorldTrackingConfiguration()
        configuration.detectionImages = Set(arAnchors)

        // Run the view's session
        sceneView.session.run(configuration)
    }
        
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
}

//Mark:- ARSCNViewDelegate
extension BookARViewController {
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        SCNNode(geometry: SCNSphere(radius: 0.1))
    }
}

//Mark:- file access
extension BookARViewController {
    private func getARAnchors() -> [ARReferenceImage] {
        var arImages: [ARReferenceImage] = []
        let fileManager = FileManager()
        for anchor in bookAnchorContentNames.keys {
            let path = bookDirectoryPath.appending("/" + anchor)
            guard fileManager.fileExists(atPath: path), let image = UIImage(contentsOfFile: path) else {
                print("anchor file does not exist")
                continue
            }
            
            guard let imageToCIImage = CIImage(image: image), let cgImage = convertCIImageToCGImage(inputImage: imageToCIImage) else {
                print("Can not convert UIImage to CGIImage \(path)")
                continue
            }

            let arImage = ARReferenceImage(cgImage, orientation: CGImagePropertyOrientation.up, physicalWidth: 0.2)
            arImages.append(arImage)
        }
        return arImages
    }
    
    private func convertCIImageToCGImage(inputImage: CIImage) -> CGImage? {
        let context = CIContext(options: nil)
        if let cgImage = context.createCGImage(inputImage, from: inputImage.extent) {
         return cgImage
        }
        return nil
    }
}
