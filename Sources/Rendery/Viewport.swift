/// The abstraction of a viewport.
///
/// A viewport designates a region within a render target (e.g., a window) that displays a scene's
/// contents, as observed from a node holding a camera (a.k.a. a point of view). If two viewports
/// overlap, the order in which they are registered in the window is used to determine the one that
/// obscures the other.
///
/// The region of a viewport is measured in normalized coordinates, so that it can be resized along
/// the render target. It is used after the scene coordinates have been projected by the camera to
/// obtain an object's the final position on the render target.
///
/// The dimensions of a viewport define an aspect ratio. Cameras maintain their own aspect ratio,
/// that should typically matches that of the viewport to avoid any kind of distortion.
public final class Viewport {

  /// Initializes a viewport with the region of the rendre target it designates.
  ///
  /// - Parameters:
  ///   - target: The target for the rendering operations.
  ///   - region: The region of the render target designated by the viewport, in normalized
  ///     coordinates (i.e., expressed in values between `0` and `1`).
  internal init(target: RenderTarget, region: Rectangle) {
    self.target = target
    self.region = region
  }

  /// The viewport's target.
  public unowned let target: RenderTarget

  /// The viewport's region.
  public var region: Rectangle

  /// The scene currently presented by the viewport.
  public private(set) var scene: Scene?

  /// The node from which the scene is viewed for rendering.
  ///
  /// This property should be assigned to a node with an attached camera. The node will provide the
  /// position and orientation of the camera, while the camera itself will be used to set rendering
  /// parameters such as the projection type, field of view and viewing frustum.
  ///
  /// The scene will not be rendered if `pointOfView` is `nil`, or if it has no camera attached.
  public weak var pointOfView: Node?

  /// The viewport's view-projection matrix.
  public var viewProjMatrix: Matrix4? {
    guard let pov = pointOfView, let camera = pov.camera
      else { return nil }

    let scaledRegion = region.scaled(x: Double(target.width), y: Double(target.height))
    let projection = camera.projection(onto: scaledRegion)

    let view = pov.sceneTransform.inverted
    return projection * view
  }

  /// Computes the viewport's frustum.
  ///
  /// - Parameters:
  ///   - up: A normalized vector pointing to the "up" direction.
  ///   - right: A normalized vector pointing to the "right" direction.
  ///
  /// - Returns: The frustum defining the portion of the scene that is visible from this viewport,
  ///   or `nil` if the viewport has no camera.
  public func frustum(up: Vector3 = .unitY, right: Vector3 = .unitX) -> Frustum? {
    guard let pov = pointOfView, let camera = pov.camera
      else { return nil }

    // Compute the aspect ratio.
    let ratio: Double
    if case .fixed(let value) = camera.aspectRatio {
      ratio = value
    } else {
      let scaled = region.scaled(x: Double(target.width), y: Double(target.height))
      ratio = scaled.width / scaled.height
    }

    // Compute the center position of the near and far clipping planes.
    let direction = (pov.sceneRotation * up.cross(right))
    let nc = pov.sceneTranslation + direction * camera.nearDistance
    let fc = pov.sceneTranslation + direction * camera.farDistance

    // Compute (half) the height of the near and far clipping planes.
    let nh, fh: Double
    switch camera.projectionType {
    case .perspective:
      nh = Double.tan(camera.fovY.radians * 0.5) * camera.nearDistance
      fh = Double.tan(camera.fovY.radians * 0.5) * camera.farDistance

    case .orthographic:
      nh = Double.tan(camera.fovY.radians * 0.5) * camera.focusDistance
      fh = nh
    }

    // Compute (half) the width of the near and far clipping planes.
    let nw = nh * ratio
    let fw = fh * ratio

    // Extract the frustum's corners. Note that this should be equivalent the projection of each
    // corner expressed in NDC using the inverted view-projection matrix.
    return Frustum(
      nearTopLeft     : nc + (up * nh) - (right * nw),
      nearBottomLeft  : nc - (up * nh) - (right * nw),
      nearBottomRight : nc - (up * nh) + (right * nw),
      nearTopRight    : nc + (up * nh) + (right * nw),
      farTopLeft      : fc + (up * fh) - (right * fw),
      farBottomLeft   : fc - (up * fh) - (right * fw),
      farBottomRight  : fc - (up * fh) + (right * fw),
      farTopRight     : fc + (up * fh) + (right * fw))
  }

  /// The root view of the viewport's heads-up display (HUD).
  public lazy var hud = ViewportRootView(viewport: self)

  /// A flag that indicates whether the viewport displayes a frame reate indicator.
  public var showsFrameRate: Bool = false

  /// Sets the specified scene as the viewport's rendered contents.
  ///
  /// The new scene immediately replaces the current scene, if one exists.
  ///
  /// - Parameters:
  ///   - newScene: The scene to present.
  ///   - pointOfView: A node representing the point from which the scene is viewed. If unassigned,
  ///     this method will attempt to use the first node with an attached camera it can find.
  public func present(scene newScene: Scene, from pointOfView: Node? = nil) {
    scene?.willMove(from: self, successor: newScene)
    newScene.willMove(to: self)

    scene = newScene
    self.pointOfView = pointOfView ?? newScene.root
      .descendants(.satisfying({ node in node.camera != nil })).first
    if self.pointOfView == nil {
      LogManager.main.log("Presented scene has no point of view.", level: .debug)
    }
  }

  /// Dimisses the scene currently presented by the viewport, if any.
  public func dismissScene() {
    scene?.willMove(from: self, successor: nil)
    scene = nil
  }

  /// Updates the viewport's contents in its render target.
  ///
  /// This method is called by the viewport's render target when it wishes to update.
  ///
  /// - Parameter pipeline: The render pipeline that's used to render the viewport's scene.
  internal func update(through pipeline: RenderPipeline) {
    guard let scene = self.scene
      else { return }

    let renderContext = AppContext.shared.renderContext

    // Update the scene's arrays of model and light nodes if necessary.
    if scene.shoudUpdateModelAndLightNodeCache {
      scene.updateModelAndLightNodeCache()
    }

    // Update transform constraints.
    for node in scene.constraintCache.keys {
      scene.updateConstraints(on: node, generation: renderContext.generation)
    }

    // Compute the actual region of the render target designated by the viewport.
    let scaledRegion = region.scaled(x: Double(target.width), y: Double(target.height))
    renderContext.set(viewportRegion: scaledRegion)

    // Enable the scissor test so that rendering can only occur in the viewport's region.
    renderContext.set(scissorRegion: scaledRegion)
    defer { renderContext.disableScissor() }

    // Clear the render context's cache.
    renderContext.modelMatrices.removeAll(keepingCapacity: true)
    renderContext.modelViewProjMatrices.removeAll(keepingCapacity: true)
    renderContext.normalMatrices.removeAll(keepingCapacity: true)

    // Send the scene through the render pipeline.
    pipeline.render(viewport: self, in: renderContext)

    // Prepare the render context to draw UI elements.
    renderContext.isBlendingEnabled = true
    renderContext.isDepthTestEnabled = false

    // Configure the UI view renderer.
    viewRenderer.dimensions = scaledRegion.dimensions
    viewRenderer.penPosition = .zero
    viewRenderer.defaultFontFace = AppContext.shared.defaultFontFace

    // Draw the scene's HUD.
    hud.draw(in: &viewRenderer)

    if showsFrameRate {
      let rate = (target as? Window)?.frameRate ?? 0
      viewRenderer.penPosition = Vector2(x: 16.0, y: 16.0)
      TextView(verbatim: "\(rate)", face: AppContext.shared.defaultFontFace)
        .setting(color: Color.red)
        .draw(in: &viewRenderer)
    }
  }

  private var viewRenderer = ViewRenderer()

  /// Unprojects the specified normalized device coordinates into the scene space.
  public func unproject(ndc: Vector3, with ivp: Matrix4) -> Vector3 {
    let x = ivp[0,0] * ndc.x + ivp[0,1] * ndc.y + ivp[0,2] * ndc.z + ivp[0,3]
    let y = ivp[1,0] * ndc.x + ivp[1,1] * ndc.y + ivp[1,2] * ndc.z + ivp[1,3]
    let z = ivp[2,0] * ndc.x + ivp[2,1] * ndc.y + ivp[2,2] * ndc.z + ivp[2,3]
    let w = ivp[3,0] * ndc.x + ivp[3,1] * ndc.y + ivp[3,2] * ndc.z + ivp[3,3]

    return Vector3(x: x / w, y: y / w, z: z / w)
  }

  /// Converts a point from the the normalized coordinate system of the viewport's target to the
  /// normalized coordinate system of this viewport.
  ///
  /// - Parameter screenPoint: A point in the coordinate system of the viewport's target.
  public func convert(fromScreenSpace screenPoint: Vector2) -> Vector2 {
    return (screenPoint - region.origin) / region.dimensions
  }

  /// Returns a ray that starts at the camera's position and is oriented so that it intersects the
  /// back of the viewport's frustrum at the specified screen coordinates.
  ///
  /// The ray's origin and direction is computed by unprojecting the specified screen point (i.e.,
  /// a position on the viewport's target) into the scene space. The origin corresponds to the
  /// unprojection on the camera's near plane, while the direction is determined by the position
  /// of the screen point on the far plane.
  ///
  /// If the viewport does not cover the entire render target, the specified screen point is first
  /// projected to viewport space (a.k.a. clip space) before computing scene coordinates.
  ///
  /// - Parameter screenPoint: The screen point from which the ray should shoot.
  ///
  /// - Returns: A ray or `nil` if the viewport has no point of view.
  public func ray(fromScreenPoint screenPoint: Vector2) -> Ray? {
    // Compute the inverted view-projection matrix, that unprojects NDCs back to the scene space.
    guard let ivp = viewProjMatrix?.inverted
      else { return nil }

    // Compute the screen point in NDCs.
    let clipPoint = convert(fromScreenSpace: screenPoint)
    let devicePoint = Vector2(x: 2.0 * clipPoint.x - 1.0, y: 1.0 - 2.0 * clipPoint.y)

    // The usual technique is to unproject the near point at 0 on the z-axis. However, its position
    // on near plane is required to compute the ray's origin with an orthographic camera, since it
    // doesn't have any convergence point. Unprojecting the point at -1 rather than 0 shouldn't
    // change the direction. However, for a perspective camera, the camera's position can be used
    // as the ray's origin.

    let np = unproject(ndc: Vector3(x: devicePoint.x, y: devicePoint.y, z: -1.0), with: ivp)
    let fp = unproject(ndc: Vector3(x: devicePoint.x, y: devicePoint.y, z: 0.99), with: ivp)
    return Ray(origin: np, direction: (fp - np).normalized)
  }

  /// A callback that is called when the viewport recieved a key press event.
  public var didKeyPress: ((KeyEvent) -> Void)?

  /// A callback that is called when the viewport recieved a key release event.
  public var didKeyRelease: ((KeyEvent) -> Void)?

  /// A callback that is called when the viewport recieved a mouse press event.
  public var didMousePress: ((MouseEvent) -> Void)?

  /// A callback that is called when the viewport recieved a mouse release event.
  public var didMouseRelease: ((MouseEvent) -> Void)?

}

extension Viewport: InputResponder {

  public var nextResponder: InputResponder? {
    // Note that for mouse events, returning `target` as the next responder discards any obscured
    // viewport to which the event could have been dispatched.
    return target as? InputResponder
  }

  public func respondToKeyPress(with event: KeyEvent) {
    if let didKeyPress = self.didKeyPress {
      didKeyPress(event)
    } else {
      nextResponder?.respondToKeyPress(with: event)
    }
  }

  public func respondToKeyRelease(with event: KeyEvent) {
    if let didKeyRelease = self.didKeyRelease {
      didKeyRelease(event)
    } else {
      nextResponder?.respondToKeyRelease(with: event)
    }
  }

  public func respondToMousePress(with event: MouseEvent) {
    if let didMousePress = self.didMousePress {
      didMousePress(event)
    } else {
      nextResponder?.respondToMousePress(with: event)
    }
  }

  public func respondToMouseRelease(with event: MouseEvent) {
    if let didMouseRelease = self.didMouseRelease {
      didMouseRelease(event)
    } else {
      nextResponder?.respondToMouseRelease(with: event)
    }
  }

}
