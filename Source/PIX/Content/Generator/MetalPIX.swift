//
//  MetalGeneratorPIX.swift
//  Pixels
//
//  Created by Hexagons on 2018-09-07.
//  Open Source - MIT License
//

import Metal

/// Metal Shader (Generator)
///
/// vars: pi, u, v, uv
///
/// Example:
/// ~~~~swift
/// let metalPix = MetalPIX(res: ._1080p, code:
///     """
///     pix = float4(u, v, 0.0, 1.0);
///     """
/// )
/// ~~~~
public class MetalPIX: PIXGenerator, PIXMetal {
    
    override open var shader: String { return "contentGeneratorMetalPIX" }
    
    // MARK: - Private Properties

    let metalFileName = "ContentGeneratorMetalPIX.metal"
    
    public override var shaderNeedsAspect: Bool { return true }
    
    public var metalUniforms: [MetalUniform] { didSet { bakeFrag() } }
    
    public var code: String { didSet { bakeFrag() } }
    public var isRawCode: Bool = false
    var metalCode: String? {
        if isRawCode { return code }
        console = nil
        do {
          return try pixels.embedMetalCode(uniforms: metalUniforms, code: code, fileName: metalFileName)
        } catch {
            pixels.log(pix: self, .error, .metal, "Metal code could not be generated.", e: error)
            return nil
        }
    }
    public var console: String?
    
    // MARK: - Property Helpers
    
    override public var liveValues: [LiveValue] {
        return metalUniforms.map({ uniform -> LiveFloat in return uniform.value })
    }
    
    // MARK: - Life Cycle
    
    public init(res: Res, uniforms: [MetalUniform] = [], code: String) {
        metalUniforms = uniforms
        self.code = code
        super.init(res: res)
//        bakeFrag()
    }
    
    required init(res: Res) {
        metalUniforms = []
        code = ""
        super.init(res: res)
    }
    
    func bakeFrag() {
        do {
            let frag = try pixels.makeMetalFrag(shader, from: self)
            try makePipeline(with: frag)
        } catch {
            switch error {
            case Pixels.ShaderError.metalError(let codeError, let errorFrag):
                pixels.log(pix: self, .fatal, nil, "Metal code failed.", e: codeError)
                console = codeError.localizedDescription
                do {
                    try makePipeline(with: errorFrag)
                } catch {
                    pixels.log(pix: self, .fatal, nil, "Metal fail failed.", e: error)
                }
            default:
                pixels.log(pix: self, .fatal, nil, "Metal bake failed.", e: error)
            }
        }
    }
    
    func makePipeline(with frag: MTLFunction) throws {
        let vtx: MTLFunction? = customVertexShaderName != nil ? try pixels.makeVertexShader(customVertexShaderName!, with: customMetalLibrary) : nil
        pipeline = try pixels.makeShaderPipeline(frag, with: vtx)
        setNeedsRender()
    }
    
}

public extension MetalPIX {
    
    static func _uv(res: Res) -> MetalPIX {
        let metalPix = MetalPIX(res: res, code:
            """
            pix = float4(u, v, 0.0, 1.0);
            """
        )
        metalPix.name = "uv:metal"
        return metalPix
    }
    
}
