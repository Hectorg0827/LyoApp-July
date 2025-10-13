//
//  Avatar3DRenderer.swift
//  LyoApp
//
//  SceneKit-based 3D Avatar Renderer
//  Real-time preview with camera controls
//  Created: October 10, 2025
//

import SwiftUI
import SceneKit

// MARK: - Avatar 3D Preview View

struct Avatar3DPreviewView: UIViewRepresentable {
    @ObservedObject var avatar: Avatar3DModel
    var cameraControlsEnabled: Bool = true
    var autoRotate: Bool = false
    
    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView()
        sceneView.backgroundColor = .clear
        sceneView.autoenablesDefaultLighting = false
        sceneView.allowsCameraControl = cameraControlsEnabled
        sceneView.antialiasingMode = .multisampling4X
        
        // Create scene
        let scene = SCNScene()
        sceneView.scene = scene
        
        // Setup camera
        let cameraNode = createCameraNode()
        scene.rootNode.addChildNode(cameraNode)
        
        // Setup lighting
        addLighting(to: scene.rootNode)
        
        // Create avatar node
        let avatarNode = createAvatarNode(from: avatar)
        avatarNode.name = "avatarRoot"
        scene.rootNode.addChildNode(avatarNode)
        
        // Auto-rotate animation if enabled
        if autoRotate {
            let rotation = SCNAction.repeatForever(
                SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 8)
            )
            avatarNode.runAction(rotation)
        }
        
        return sceneView
    }
    
    func updateUIView(_ sceneView: SCNView, context: Context) {
        guard let scene = sceneView.scene else { return }
        
        // Find and update avatar node
        if let avatarNode = scene.rootNode.childNode(withName: "avatarRoot", recursively: false) {
            updateAvatarAppearance(node: avatarNode, with: avatar)
        }
    }
    
    // MARK: - Scene Setup
    
    private func createCameraNode() -> SCNNode {
        let camera = SCNCamera()
        camera.fieldOfView = 50
        camera.zNear = 0.1
        camera.zFar = 100
        
        let cameraNode = SCNNode()
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 3)
        cameraNode.look(at: SCNVector3(x: 0, y: 0, z: 0))
        
        return cameraNode
    }
    
    private func addLighting(to node: SCNNode) {
        // Key light (main light)
        let keyLight = SCNLight()
        keyLight.type = .directional
        keyLight.color = UIColor.white
        keyLight.intensity = 1000
        let keyLightNode = SCNNode()
        keyLightNode.light = keyLight
        keyLightNode.position = SCNVector3(x: 5, y: 10, z: 10)
        keyLightNode.look(at: SCNVector3Zero)
        node.addChildNode(keyLightNode)
        
        // Fill light (softer, opposite side)
        let fillLight = SCNLight()
        fillLight.type = .directional
        fillLight.color = UIColor(white: 0.8, alpha: 1.0)
        fillLight.intensity = 500
        let fillLightNode = SCNNode()
        fillLightNode.light = fillLight
        fillLightNode.position = SCNVector3(x: -5, y: 5, z: 5)
        fillLightNode.look(at: SCNVector3Zero)
        node.addChildNode(fillLightNode)
        
        // Back light (rim light)
        let backLight = SCNLight()
        backLight.type = .directional
        backLight.color = UIColor(white: 0.9, alpha: 1.0)
        backLight.intensity = 300
        let backLightNode = SCNNode()
        backLightNode.light = backLight
        backLightNode.position = SCNVector3(x: 0, y: 3, z: -5)
        backLightNode.look(at: SCNVector3Zero)
        node.addChildNode(backLightNode)
        
        // Ambient light
        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.color = UIColor(white: 0.3, alpha: 1.0)
        ambientLight.intensity = 200
        let ambientLightNode = SCNNode()
        ambientLightNode.light = ambientLight
        node.addChildNode(ambientLightNode)
    }
    
    // MARK: - Avatar Creation
    
    private func createAvatarNode(from model: Avatar3DModel) -> SCNNode {
        let containerNode = SCNNode()
        
        // Load base model based on species
        let baseNode = createBaseNode(for: model.species)
        containerNode.addChildNode(baseNode)
        
        // Apply facial features
        applyFacialFeatures(to: baseNode, features: model.facialFeatures, gender: model.gender)
        
        // Add hair
        if let hairNode = createHairNode(config: model.hair) {
            baseNode.addChildNode(hairNode)
        }
        
        // Add clothing
        addClothing(to: baseNode, clothing: model.clothing)
        
        // Add accessories
        for accessory in model.accessories {
            if let accessoryNode = createAccessoryNode(accessory: accessory) {
                baseNode.addChildNode(accessoryNode)
            }
        }
        
        return containerNode
    }
    
    private func createBaseNode(for species: AvatarSpecies) -> SCNNode {
        // In production, load actual 3D models from bundle
        // For now, create procedural geometry
        
        let baseNode = SCNNode()
        
        switch species {
        case .human:
            baseNode.addChildNode(createHumanBase())
        case .animal:
            baseNode.addChildNode(createAnimalBase())
        case .robot:
            baseNode.addChildNode(createRobotBase())
        }
        
        return baseNode
    }
    
    private func createHumanBase() -> SCNNode {
        let containerNode = SCNNode()
        
        // Body (for breathing animation)
        let bodyGeometry = SCNCapsule(capRadius: 0.3, height: 0.8)
        bodyGeometry.firstMaterial?.diffuse.contents = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
        let body = SCNNode(geometry: bodyGeometry)
        body.position = SCNVector3(x: 0, y: -0.9, z: 0)
        body.name = "body"
        containerNode.addChildNode(body)
        
        // Head container
        let headNode = SCNNode()
        headNode.position = SCNVector3(x: 0, y: 0, z: 0)
        containerNode.addChildNode(headNode)
        
        // Head
        let headGeometry = SCNSphere(radius: 0.5)
        headGeometry.firstMaterial?.diffuse.contents = UIColor(red: 1.0, green: 0.87, blue: 0.74, alpha: 1.0)
        let head = SCNNode(geometry: headGeometry)
        head.name = "head"
        headNode.addChildNode(head)
        
        // Eyes
        let leftEye = createEye()
        leftEye.position = SCNVector3(x: -0.15, y: 0.1, z: 0.4)
        leftEye.name = "leftEye"
        headNode.addChildNode(leftEye)
        
        let rightEye = createEye()
        rightEye.position = SCNVector3(x: 0.15, y: 0.1, z: 0.4)
        rightEye.name = "rightEye"
        headNode.addChildNode(rightEye)
        
        // Nose
        let noseGeometry = SCNCone(topRadius: 0.03, bottomRadius: 0.06, height: 0.15)
        noseGeometry.firstMaterial?.diffuse.contents = UIColor(red: 1.0, green: 0.87, blue: 0.74, alpha: 1.0)
        let nose = SCNNode(geometry: noseGeometry)
        nose.position = SCNVector3(x: 0, y: -0.05, z: 0.45)
        nose.eulerAngles = SCNVector3(x: Float.pi / 2, y: 0, z: 0)
        nose.name = "nose"
        headNode.addChildNode(nose)
        
        // Mouth
        let mouthGeometry = SCNCapsule(capRadius: 0.15, height: 0.02)
        mouthGeometry.firstMaterial?.diffuse.contents = UIColor(red: 0.8, green: 0.3, blue: 0.3, alpha: 1.0)
        let mouth = SCNNode(geometry: mouthGeometry)
        mouth.position = SCNVector3(x: 0, y: -0.25, z: 0.4)
        mouth.eulerAngles = SCNVector3(x: 0, y: 0, z: Float.pi / 2)
        mouth.name = "mouth"
        headNode.addChildNode(mouth)
        
        return containerNode
    }
    
    private func createAnimalBase() -> SCNNode {
        let animalNode = SCNNode()
        
        // Simple animal head (e.g., cat/dog)
        let headGeometry = SCNSphere(radius: 0.4)
        headGeometry.firstMaterial?.diffuse.contents = UIColor.brown
        let head = SCNNode(geometry: headGeometry)
        head.name = "head"
        animalNode.addChildNode(head)
        
        // Ears
        let earGeometry = SCNCone(topRadius: 0.05, bottomRadius: 0.15, height: 0.3)
        earGeometry.firstMaterial?.diffuse.contents = UIColor.brown
        
        let leftEar = SCNNode(geometry: earGeometry)
        leftEar.position = SCNVector3(x: -0.3, y: 0.4, z: 0)
        leftEar.eulerAngles = SCNVector3(x: Float.pi / 6, y: 0, z: -Float.pi / 4)
        animalNode.addChildNode(leftEar)
        
        let rightEar = SCNNode(geometry: earGeometry)
        rightEar.position = SCNVector3(x: 0.3, y: 0.4, z: 0)
        rightEar.eulerAngles = SCNVector3(x: Float.pi / 6, y: 0, z: Float.pi / 4)
        animalNode.addChildNode(rightEar)
        
        // Eyes
        let leftEye = createEye()
        leftEye.position = SCNVector3(x: -0.15, y: 0.1, z: 0.35)
        animalNode.addChildNode(leftEye)
        
        let rightEye = createEye()
        rightEye.position = SCNVector3(x: 0.15, y: 0.1, z: 0.35)
        animalNode.addChildNode(rightEye)
        
        // Nose
        let noseGeometry = SCNSphere(radius: 0.08)
        noseGeometry.firstMaterial?.diffuse.contents = UIColor.black
        let nose = SCNNode(geometry: noseGeometry)
        nose.position = SCNVector3(x: 0, y: -0.1, z: 0.38)
        animalNode.addChildNode(nose)
        
        return animalNode
    }
    
    private func createRobotBase() -> SCNNode {
        let robotNode = SCNNode()
        
        // Robot head (box)
        let headGeometry = SCNBox(width: 0.8, height: 0.8, length: 0.8, chamferRadius: 0.1)
        headGeometry.firstMaterial?.diffuse.contents = UIColor.gray
        headGeometry.firstMaterial?.metalness.contents = 0.8
        headGeometry.firstMaterial?.roughness.contents = 0.2
        let head = SCNNode(geometry: headGeometry)
        head.name = "head"
        robotNode.addChildNode(head)
        
        // Antenna
        let antennaGeometry = SCNCylinder(radius: 0.03, height: 0.3)
        antennaGeometry.firstMaterial?.diffuse.contents = UIColor.darkGray
        antennaGeometry.firstMaterial?.metalness.contents = 1.0
        let antenna = SCNNode(geometry: antennaGeometry)
        antenna.position = SCNVector3(x: 0, y: 0.55, z: 0)
        robotNode.addChildNode(antenna)
        
        let antennaBallGeometry = SCNSphere(radius: 0.08)
        antennaBallGeometry.firstMaterial?.diffuse.contents = UIColor.red
        antennaBallGeometry.firstMaterial?.emission.contents = UIColor.red
        let antennaBall = SCNNode(geometry: antennaBallGeometry)
        antennaBall.position = SCNVector3(x: 0, y: 0.7, z: 0)
        robotNode.addChildNode(antennaBall)
        
        // Eyes (LED panels)
        let eyeGeometry = SCNBox(width: 0.2, height: 0.15, length: 0.05, chamferRadius: 0.02)
        eyeGeometry.firstMaterial?.diffuse.contents = UIColor.cyan
        eyeGeometry.firstMaterial?.emission.contents = UIColor.cyan
        
        let leftEye = SCNNode(geometry: eyeGeometry)
        leftEye.position = SCNVector3(x: -0.2, y: 0.1, z: 0.4)
        leftEye.name = "leftEye"
        robotNode.addChildNode(leftEye)
        
        let rightEye = SCNNode(geometry: eyeGeometry)
        rightEye.position = SCNVector3(x: 0.2, y: 0.1, z: 0.4)
        rightEye.name = "rightEye"
        robotNode.addChildNode(rightEye)
        
        // Mouth (grille)
        let mouthGeometry = SCNBox(width: 0.4, height: 0.1, length: 0.05, chamferRadius: 0.02)
        mouthGeometry.firstMaterial?.diffuse.contents = UIColor.darkGray
        let mouth = SCNNode(geometry: mouthGeometry)
        mouth.position = SCNVector3(x: 0, y: -0.2, z: 0.4)
        mouth.name = "mouth"
        robotNode.addChildNode(mouth)
        
        return robotNode
    }
    
    private func createEye() -> SCNNode {
        let eyeContainer = SCNNode()
        
        // Eye white
        let whiteGeometry = SCNSphere(radius: 0.08)
        whiteGeometry.firstMaterial?.diffuse.contents = UIColor.white
        let white = SCNNode(geometry: whiteGeometry)
        eyeContainer.addChildNode(white)
        
        // Iris
        let irisGeometry = SCNSphere(radius: 0.06)
        irisGeometry.firstMaterial?.diffuse.contents = UIColor.blue
        let iris = SCNNode(geometry: irisGeometry)
        iris.position = SCNVector3(x: 0, y: 0, z: 0.05)
        eyeContainer.addChildNode(iris)
        
        // Pupil
        let pupilGeometry = SCNSphere(radius: 0.03)
        pupilGeometry.firstMaterial?.diffuse.contents = UIColor.black
        let pupil = SCNNode(geometry: pupilGeometry)
        pupil.position = SCNVector3(x: 0, y: 0, z: 0.08)
        eyeContainer.addChildNode(pupil)
        
        return eyeContainer
    }
    
    // MARK: - Feature Application
    
    private func applyFacialFeatures(to node: SCNNode, features: FacialFeatures, gender: AvatarGender) {
        // Update eye color
          if let leftEye = node.childNode(withName: "leftEye", recursively: true),
              let rightEye = node.childNode(withName: "rightEye", recursively: true) {
                let irisColor = features.resolvedEyeColor
                updateEyeColor(leftEye, color: irisColor)
                updateEyeColor(rightEye, color: irisColor)
            
            // Update eye size
            let scale = Float(features.eyeSize)
            leftEye.scale = SCNVector3(scale, scale, scale)
            rightEye.scale = SCNVector3(scale, scale, scale)
            
            // Update eye spacing
            let spacing = Float(features.eyeSpacing)
            leftEye.position.x = -0.15 * spacing
            rightEye.position.x = 0.15 * spacing
        }
        
        // Update nose
        if let nose = node.childNode(withName: "nose", recursively: true) {
            let noseScale = Float(features.noseSize)
            nose.scale = SCNVector3(noseScale, noseScale, noseScale)
        }
        
        // Update mouth/lip color
        if let mouth = node.childNode(withName: "mouth", recursively: true) {
            mouth.geometry?.firstMaterial?.diffuse.contents = UIColor(features.lipColor)
        }
        
        // Apply face shape (would modify head geometry in production)
        if let head = node.childNode(withName: "head", recursively: true) {
            switch features.faceShape {
            case .round:
                head.scale = SCNVector3(1.1, 1.0, 1.1)
            case .oval:
                head.scale = SCNVector3(0.95, 1.05, 1.0)
            case .square:
                head.scale = SCNVector3(1.0, 0.95, 1.0)
            case .heart:
                head.scale = SCNVector3(1.0, 1.0, 0.95)
            case .long:
                head.scale = SCNVector3(0.9, 1.15, 1.0)
            case .diamond:
                head.scale = SCNVector3(1.05, 1.0, 0.95)
            }
        }
    }
    
    private func updateEyeColor(_ eyeNode: SCNNode, color: Color) {
        // Find iris node (2 levels down typically)
        if let iris = eyeNode.childNodes.first?.childNodes.first {
            iris.geometry?.firstMaterial?.diffuse.contents = UIColor(color)
        }
    }
    
    private func createHairNode(config: HairConfiguration) -> SCNNode? {
        guard config.style != .bald else { return nil }
        
        let hairNode = SCNNode()
        hairNode.name = "hair"
        
        // Create hair geometry based on style
        let hairGeometry: SCNGeometry
        
        switch config.style {
        case .short, .pixie, .crew, .undercut, .bob, .shortCurly:
            hairGeometry = SCNCapsule(capRadius: 0.52, height: 0.25)
        case .medium, .shoulder, .lob, .shag, .layers:
            hairGeometry = SCNCapsule(capRadius: 0.53, height: 0.3)
        case .long, .straight:
            hairGeometry = SCNCapsule(capRadius: 0.55, height: 0.35)
        case .curly, .wavy:
            hairGeometry = SCNSphere(radius: 0.55)
        case .ponytail:
            hairGeometry = SCNCapsule(capRadius: 0.53, height: 0.3)
        case .bun:
            hairGeometry = SCNCapsule(capRadius: 0.53, height: 0.3)
        case .braids:
            hairGeometry = SCNCapsule(capRadius: 0.52, height: 0.35)
        case .dreadlocks:
            hairGeometry = SCNCapsule(capRadius: 0.52, height: 0.4)
        case .mohawk:
            hairGeometry = SCNBox(width: 0.2, height: 0.6, length: 0.8, chamferRadius: 0.1)
        case .afro:
            hairGeometry = SCNSphere(radius: 0.65)
        case .buzz:
            hairGeometry = SCNCapsule(capRadius: 0.51, height: 0.1)
        case .bald:
            return nil
        }
        
        hairGeometry.firstMaterial?.diffuse.contents = UIColor(config.resolvedBaseColor)
        let hair = SCNNode(geometry: hairGeometry)
        hair.position = SCNVector3(x: 0, y: 0.3, z: 0)
        hairNode.addChildNode(hair)
        
        // Add highlights if enabled
        if config.hasHighlights, let highlightColor = config.resolvedHighlightColor {
            let highlightGeometry = SCNCapsule(capRadius: 0.53, height: 0.25)
            highlightGeometry.firstMaterial?.diffuse.contents = UIColor(highlightColor)
            highlightGeometry.firstMaterial?.transparency = 0.5
            let highlight = SCNNode(geometry: highlightGeometry)
            highlight.position = SCNVector3(x: 0, y: 0.3, z: 0.1)
            hairNode.addChildNode(highlight)
        }
        
        return hairNode
    }
    
    private func addClothing(to node: SCNNode, clothing: ClothingSet) {
        // In production, load actual clothing models
        // For now, add simple colored geometry below head
        
        // Top
        let topGeometry = SCNCylinder(radius: 0.6, height: 0.8)
        topGeometry.firstMaterial?.diffuse.contents = UIColor(clothing.top?.color ?? .blue)
        let topNode = SCNNode(geometry: topGeometry)
        topNode.position = SCNVector3(x: 0, y: -0.9, z: 0)
        topNode.name = "clothing_top"
        node.addChildNode(topNode)
    }
    
    private func createAccessoryNode(accessory: Accessory) -> SCNNode? {
        let accessoryNode = SCNNode()
        accessoryNode.name = "accessory_\(accessory.id.uuidString)"
        
        switch accessory.type {
        case .glasses, .sunglasses:
            // Simple glasses frame
            let frameGeometry = SCNTorus(ringRadius: 0.12, pipeRadius: 0.02)
            frameGeometry.firstMaterial?.diffuse.contents = UIColor(accessory.color)
            
            let leftLens = SCNNode(geometry: frameGeometry)
            leftLens.position = SCNVector3(x: -0.15, y: 0.1, z: 0.45)
            accessoryNode.addChildNode(leftLens)
            
            let rightLens = SCNNode(geometry: frameGeometry)
            rightLens.position = SCNVector3(x: 0.15, y: 0.1, z: 0.45)
            accessoryNode.addChildNode(rightLens)
            
        case .hat:
            // Simple hat
            let hatGeometry = SCNCone(topRadius: 0.3, bottomRadius: 0.55, height: 0.4)
            hatGeometry.firstMaterial?.diffuse.contents = UIColor(accessory.color)
            let hat = SCNNode(geometry: hatGeometry)
            hat.position = SCNVector3(x: 0, y: 0.7, z: 0)
            accessoryNode.addChildNode(hat)
        case .earrings, .necklace, .bracelet, .watch, .ring:
            // Placeholder simple sphere/torus
            let jewel = SCNSphere(radius: 0.05)
            jewel.firstMaterial?.diffuse.contents = UIColor(accessory.color)
            let node = SCNNode(geometry: jewel)
            node.position = SCNVector3(x: 0.2, y: 0, z: 0.4)
            accessoryNode.addChildNode(node)
        case .backpack:
            let packGeometry = SCNBox(width: 0.4, height: 0.5, length: 0.15, chamferRadius: 0.05)
            packGeometry.firstMaterial?.diffuse.contents = UIColor(accessory.color)
            let pack = SCNNode(geometry: packGeometry)
            pack.position = SCNVector3(x: 0, y: -0.2, z: -0.4)
            accessoryNode.addChildNode(pack)
        case .other:
            let token = SCNSphere(radius: 0.05)
            token.firstMaterial?.diffuse.contents = UIColor(accessory.color)
            let node = SCNNode(geometry: token)
            node.position = SCNVector3(x: 0, y: -0.4, z: 0.3)
            accessoryNode.addChildNode(node)
        }
        
        return accessoryNode.childNodes.isEmpty ? nil : accessoryNode
    }
    
    // MARK: - Update Methods
    
    private func updateAvatarAppearance(node: SCNNode, with model: Avatar3DModel) {
        // Update facial features
        applyFacialFeatures(to: node, features: model.facialFeatures, gender: model.gender)
        
        // Update hair
        if let existingHair = node.childNode(withName: "hair", recursively: true) {
            existingHair.removeFromParentNode()
        }
        if let newHair = createHairNode(config: model.hair) {
            node.addChildNode(newHair)
        }
        
        // Update clothing
        if let existingTop = node.childNode(withName: "clothing_top", recursively: true) {
            existingTop.geometry?.firstMaterial?.diffuse.contents = UIColor(model.clothing.top?.color ?? .blue)
        }
        
        // Update accessories
        // Remove old accessories
        node.childNodes.filter { $0.name?.starts(with: "accessory_") == true }.forEach { $0.removeFromParentNode() }
        // Add new accessories
        for accessory in model.accessories {
            if let accessoryNode = createAccessoryNode(accessory: accessory) {
                node.addChildNode(accessoryNode)
            }
        }
    }
}

// MARK: - Preview Wrapper

struct Avatar3DPreviewCard: View {
    @ObservedObject var avatar: Avatar3DModel
    var height: CGFloat = 300
    var showControls: Bool = true
    
    var body: some View {
        VStack(spacing: 0) {
            Avatar3DPreviewView(avatar: avatar, cameraControlsEnabled: showControls)
                .frame(height: height)
                .background(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
            
            if showControls {
                Text("Pinch to zoom • Drag to rotate")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
            }
        }
    }
}
