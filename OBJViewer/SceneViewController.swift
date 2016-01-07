//
//  SceneViewController.swift
//  OBJViewer
//
//  Created by Todd Johnson on 1/6/16.
//  Copyright © 2016 Todd Johnson. All rights reserved.
//

import UIKit
import SceneKit

class SceneViewController: UIViewController {

    @IBOutlet weak var sceneView: SCNView!
    @IBOutlet weak var progressView: UIProgressView!
    var objFilename: String?

    override func viewDidLoad() {
        super.viewDidLoad()

        if let filename = objFilename, let path = NSBundle.mainBundle().pathForResource(filename, ofType: "obj") {
            self.navigationItem.title = filename
            self.progressView.setProgress(0, animated: false)

            let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
            dispatch_async(queue, {
                let scene = self.loadSceneFromObj(path)
                let main_queue = dispatch_get_main_queue()
                dispatch_async(main_queue, {
                    self.sceneView.scene = scene
                    self.progressView.hidden = true
                })
            })
        }
    }

    func loadSceneFromObj(path: String) -> SCNScene {
        let scene = SCNScene()

        if let reader = TextFileReader(path: path) {
            let node = SCNNode()
            defer {
                reader.close()
            }

            var vertices = [SCNVector3]()
            var normals = [SCNVector3]()
            var indices = [CInt]()
            var elements = [SCNGeometryElement]()

            let main_queue = dispatch_get_main_queue()
            let fileSize = Float(reader.fileSize)

            while let line = reader.nextLine() {
                let trimmedLine = line.stringByReplacingOccurrencesOfString("\r", withString: "")
                let parts = trimmedLine.componentsSeparatedByCharactersInSet(NSCharacterSet.whitespaceCharacterSet()).filter({ !$0.isEmpty })
                if parts.count < 1 {
                    continue
                }

                if parts[0] == "g" {
                    if indices.count > 0 {
                        // create new geometry element using current index array
                        let data = NSData(bytes: indices, length: sizeof(CInt) * indices.count)
                        let element = SCNGeometryElement(data: data, primitiveType: .Triangles, primitiveCount: indices.count/3, bytesPerIndex: sizeof(CInt))
                        // add geometry element to element array
                        elements.append(element)
                    }
                    // create new index array for faces
                    indices.removeAll()
                } else if parts[0] == "v" {
                    // parse 3 floats, add to vertex array
                    if parts.count == 4 {
                        let x = Float(parts[1])!
                        let y = Float(parts[2])!
                        let z = Float(parts[3])!
                        let vertex = SCNVector3Make(x, y, z)
                        vertices.append(vertex)
                    } else {
                        NSLog("Expected 3 values for vertex but found \(parts.count-1)")
                    }
                } else if parts[0] == "vn" {
                    // parse 3 floats, add to normals array
                    if parts.count == 4 {
                        let x = Float(parts[1])!
                        let y = Float(parts[2])!
                        let z = Float(parts[3])!
                        let normal = SCNVector3Make(x, y, z)
                        normals.append(normal)
                    } else {
                        NSLog("Expected 3 values for normal but found \(parts.count-1)")
                    }
                } else if parts[0] == "f" {
                    // indices for face
                    for i in 1..<parts.count {
                        // format is vertex[/texture[/normal]] where texture and normal indices are optional
                        let faceParts = parts[i].componentsSeparatedByString("/")
                        // check that faceParts[2] == faceParts[0] when faceParts.count > 2
                        if (faceParts.count > 2) && (faceParts[0] != faceParts[2]) {
                            NSLog("Index for vertex \(faceParts[0]) does not match index for normal \(faceParts[2])")
                        }
                        if i > 3 {
                            // add indices[count - 3] to index array
                            let index1 = indices.count - 3
                            let index2 = indices.count - 1
                            indices.append(indices[index1])
                            // add indices[count - 1] to index array
                            indices.append(indices[index2])
                        }
                        // add faceParts[0] to index array (minus 1 because file format is not 0 based)
                        let index = CInt(faceParts[0])!
                        indices.append(index - 1)
                    }
                }
                let progress = Float(reader.currentFilePosition()) / fileSize
                dispatch_async(main_queue, {
                    self.progressView.setProgress(progress, animated: false)
                })
            }

            if indices.count > 0 {
                // create new geometry element using current index array
                let data = NSData(bytes: indices, length: sizeof(CInt) * indices.count)
                let element = SCNGeometryElement(data: data, primitiveType: .Triangles, primitiveCount: indices.count/3, bytesPerIndex: sizeof(CInt))
                // add geometry element to element array
                elements.append(element)
            }

            // add vertex array and normals array as geometry sources
            var sources = [SCNGeometrySource]()
            let vertexSource = SCNGeometrySource(vertices: vertices, count: vertices.count)
            sources.append(vertexSource)
            if normals.count > 0 {
                // check that vertex array count == normals array count because SCNGeometryElement indexes both with the same value
                if vertices.count != normals.count {
                    NSLog("Vertex count is \(vertices.count) but normal count is \(normals.count)")
                }
                
                let normalSource = SCNGeometrySource(normals: normals, count: normals.count)
                sources.append(normalSource)
            }

            let grayMaterial = SCNMaterial()
            grayMaterial.diffuse.contents = UIColor.grayColor()

            let geometry = SCNGeometry(sources: sources, elements: elements)
            geometry.materials = [grayMaterial]
            node.geometry = geometry

            scene.rootNode.addChildNode(node)
        }
        
        return scene
    }
}
