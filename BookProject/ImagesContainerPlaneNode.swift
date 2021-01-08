//
//  ImagesContainerPlaneNode.swift
//  BookProject
//
//  Created by Kunal Patil on 1/4/21.
//

import UIKit
import SceneKit
import AVKit

let imageWidthDimension: CGFloat = 0.2



final class ImagesContainerPlaneNode: SCNNode {
  //  let images: ArrayWithCyclingIndex
  // let videos: ArrayWithCyclingIndex
  let mixedContent: ArrayWithCyclingIndex
    
  /*  init(images: [UIImage]) {
        self.images = ArrayWithCyclingIndex(array: images)
        super.init()
        prepareGeometry()
        simdOrientation = simd_quatf(angle: Float.pi/2, axis: simd_float3(x: -1, y: 0, z: 0))
    }*/
    
    init(mixedContent: [AssetContainer] ) {
          self.mixedContent = ArrayWithCyclingIndex(array: mixedContent)
          super.init()
          prepareGeometry()
          simdOrientation = simd_quatf(angle: Float.pi/2, axis: simd_float3(x: -1, y: 0, z: 0))
      }
      
    
    
    func showNextImage() {
        //images.cycleIndex()
        mixedContent.cycleIndex()
        prepareGeometry()
    }
    
    /*private func prepareGeometry() {
        guard let image = images.currentValue as? UIImage else { return }
        let imageAspectRatio = image.size.width / image.size.height
        geometry = SCNPlane(width: imageWidthDimension, height: imageWidthDimension / imageAspectRatio)
        geometry?.firstMaterial?.diffuse.contents = images.currentValue
        geometry?.firstMaterial?.locksAmbientWithDiffuse = true
        
    }*/
    
    private func prepareGeometry(){
        
        guard let assetContainer = mixedContent.currentValue as? AssetContainer else {
            print("error: mixed content has non AssetContainer element")
            return
        }
        
        switch assetContainer.type {
        case .image:
            if let image = assetContainer.image {
                let imageAspectRatio = image.size.width / image.size.height
                geometry = SCNPlane(width: imageWidthDimension, height: imageWidthDimension / imageAspectRatio)
                geometry?.firstMaterial?.diffuse.contents = image
                geometry?.firstMaterial?.locksAmbientWithDiffuse = true
            }
        case .video:
            if let video = assetContainer.video {
            
                geometry?.firstMaterial?.diffuse.contents = video
                geometry?.firstMaterial?.locksAmbientWithDiffuse = true
                let controller = AVPlayerViewController()
                controller.player = video
                controller.player?.play()
            }
        break
        case .model3D:
            // do model stuff
        break
        }
       
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

final class ArrayWithCyclingIndex {
    let array: [Any]
    private var index: Int = 0
    init(array: [Any], index: Int = 0) {
        self.array = array
        self.index = index
    }
    
    var currentValue: Any {
        array[index]
    }
    
    func cycleIndex() {
        if index == array.count - 1 {
            index = 0
        } else {
            index += 1
        }
    }
    
}
