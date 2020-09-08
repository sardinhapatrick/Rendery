import CGLFW

/// An object that can be used to interact with Rendery's low level graphics API.
public final class RenderContext {

  // MARK: Render state

  /// Reinitializes a render context to its default settings.
  internal func reset() {
    // Enable blending and specifies how OpenGL should handle transparency.
    isBlendingEnabled = true
    isAlphaPremultiplied = true

    // Enable back face culling.
    culling = .back

    // Enable depth test.
    isDepthTestEnabled = true

    // Disable stencil test.
    stencil.isEnabled = false
    stencil.setWriteMask(0xff)
    stencil.setFunction(.always(reference: 0, mask: 0xff))
    stencil.setActions(
      onStencilFailure: .keep,
      onStencilSuccessAndDepthFailure: .keep,
      onStencilAndDepthSuccess: .keep)

    // Configure OpenGL so that it performs gamma correction when writing to a sRGB target.
    glEnable(GL.FRAMEBUFFER_SRGB)
  }

  /// The generation number of the next frame to render.
  ///
  /// This number uniquely identifies a frame and can be used to invalidate cache between two
  /// render cycles.
  public internal(set) var generation: UInt64 = 0

  /// A flag that indicates whether transparent textures have their alpha-channel premultiplied.
  public var isAlphaPremultiplied = true {
    didSet {
      if isAlphaPremultiplied {
        glBlendFunc(GL.ONE, GL.ONE_MINUS_SRC_ALPHA)
      } else {
        glBlendFunc(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA)
      }
    }
  }

  /// A flag that indicates whether blending is enabled.
  public var isBlendingEnabled = true {
    didSet { glToggle(capability: GL.BLEND, isEnabled: isBlendingEnabled) }
  }

  /// The culling mode of the render system.
  public var culling = CullingMode.back {
    didSet {
      switch culling {
      case .none:
        glDisable(GL.CULL_FACE)

      case .front:
        glEnable(GL.CULL_FACE)
        glCullFace(GL.FRONT)

      case .back:
        glEnable(GL.CULL_FACE)
        glCullFace(GL.BACK)

      case .both:
        glEnable(GL.CULL_FACE)
        glCullFace(GL.FRONT_AND_BACK)
      }
    }
  }

  /// A face culling mode.
  public enum CullingMode {

    /// No culling is applied.
    case none

    /// Culling is applied on front faces.
    case front

    /// Culling is applied on back faces.
    case back

    /// Culling is applied on both front and back faces.
    case both

  }

  // A flag that indicates whether depth testing is enabled.
  public var isDepthTestEnabled = true {
    didSet { glToggle(capability: GL.DEPTH_TEST, isEnabled: isDepthTestEnabled) }
  }

  /// The stencil state of the render system.
  public var stencil = StencilState()

  // MARK: Scene properties

  // The ambient light.
  public var ambientLight: Color = .white

  /// The view-projection matrix.
  public var viewProjMatrix: Matrix4 = .zero

  /// A cache mapping nodes to their corresponding model-view-projection.
  internal var modelViewProjMatrices: [Node: Matrix4] = [:]

  /// A cache mapping nodes to their corresponding normal transformation matrix.
  internal var normalMatrices: [Node: Matrix4] = [:]

  // MARK: Graphics commands

  /// Clears the color buffer of the render target.
  ///
  /// - Parameter color: The color with which the render target should be cleared.
  public func clear(color: Color) {
    glClearColor(color.linear(gamma: AppContext.shared.gamma))
    glClear(GL.COLOR_BUFFER_BIT)
  }

  /// Sets the rendering viewport.
  ///
  /// - Parameter region: The viewport's region, in pixels.
  public func set(viewportRegion region: Rectangle) {
    glViewport(region: region)
  }

  /// Enables the scissor test for the specified region.
  ///
  /// - Parameter region: The region of the scissor test, in pixels.
  public func set(scissorRegion region: Rectangle) {
    glScissor(region: region)
    glEnable(GL.SCISSOR_TEST)
  }

  /// Disables the scissor test-
  public func disableScissor() {
    glDisable(GL.SCISSOR_TEST)
  }

  /// Draws the given models.
  ///
  /// This method draws
  ///
  /// - Parameters:
  ///   - modelNodes: A sequence of nodes with an attached model.
  ///   - material: If provided, the material used to render all meshes, overriding the material
  ///     defined by their containing model. The material must be loaded.
  ///   - lightNodes: A function that accepts a node and returns a sequence with the lights that
  ///     affect its rendering.
  public func draw<M>(
    modelNodes: M,
    material: Material? = nil,
    lightNodes: (Node) -> [Node]
  ) where M: Sequence, M.Element == Node {
    // If `material` was provided, install and set up the associated shader.
    if let m = material {
      m.shader.install()
      m.shader.assign(ambientLight, to: "u_ambientLight")
    }

    // Iterate over the given list of renderable nodes to render their attached model.
    for node in modelNodes {
      let model = node.model!

      // Iterate over all the meshes that defined the node's model.
      for (offset, mesh) in node.model!.meshes.enumerated() {
        // Makes sure the mesh is loaded.
        mesh.load()

        // Determine the mesh's material.
        let m: Material
        if let m_ = material {
          m = m_
        } else {
          if model.materials.isEmpty {
            m = Material(program: .default)
          } else {
            m = model.meshes.count <= model.materials.count
              ? model.materials[offset]
              : model.materials[offset % model.materials.count]
          }

          // Install and set up the material shader.
          try! m.shader.load()
          m.shader.install()
          m.shader.assign(ambientLight, to: "u_ambientLight")
        }

        // Compute the transformation matrices.
        var modelMatrix = node.sceneTransform
        if model.pivotPoint != Vector3(x: 0.5, y: 0.5, z: 0.5) {
          let bb = model.aabb
          let translation = (Vector3.unitScale - model.pivotPoint) * bb.dimensions + bb.origin
          modelMatrix = modelMatrix * Matrix4(translation: translation)
        }

        let modelViewProjMatrix: Matrix4
        if let mvp = modelViewProjMatrices[node] {
          modelViewProjMatrix = mvp
        } else {
          modelViewProjMatrix = viewProjMatrix * modelMatrix
          modelViewProjMatrices[node] = modelViewProjMatrix
        }

        // Set up "per-drawable" shader uniforms.
        m.shader.assign(modelMatrix, to: "u_modelMatrix")
        m.shader.assign(modelViewProjMatrix, to: "u_modelViewProjMatrix")
        m.shader.assign(
          Matrix3(upperLeftOf: modelMatrix).inverted.transposed,
          to: "u_normalMatrix")

        m.diffuse.assign(to: "u_diffuse", textureUnit: 0, in: m.shader)
        m.multiply.assign(to: "u_multiply", textureUnit: 1, in: m.shader)

        var i = 0
        for lightNode in lightNodes(node).prefix(m.shader.maxLightCount) {
          // FIXME: Handle different the lighting type.
          guard lightNode.light?.lightingType == .point
            else { continue }

          let prefix = "u_pointLights[\(i)]"
          m.shader.assign(lightNode.light!.color, to: prefix + ".color")
          m.shader.assign(lightNode.sceneTranslation, to: prefix + ".position")
          i += 1
        }
        m.shader.assign(i, to: "u_pointLightCount")

        // Draw the mesh.
        mesh.draw()
      }
    }
  }

}
