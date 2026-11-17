// Convierte una foto casera de camiseta en imagen de vitrina:
// saca el fondo y la mano, corrige luz, centra y compone sobre un fondo parejo.
// Uso: vitrina <entrada.jpg> <salida.jpg>
import Foundation
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins

let a = CommandLine.arguments
guard a.count >= 3, let src = CIImage(contentsOf: URL(fileURLWithPath: a[1]), options: [.applyOrientationProperty: true]) else { print("uso: vitrina in out"); exit(1) }
let ctx = CIContext()
let ext = src.extent

// 1) máscara de primer plano (camiseta + percha + mano)
let fgReq = VNGenerateForegroundInstanceMaskRequest()
let h = VNImageRequestHandler(ciImage: src)
try h.perform([fgReq])
guard let fg = fgReq.results?.first else { print("sin primer plano"); exit(2) }
let fgBuf = try fg.generateScaledMaskForImage(forInstances: fg.allInstances, from: h)
var mask = CIImage(cvPixelBuffer: fgBuf)

// 2) máscara de persona (mano/brazo) para restarla
let pReq = VNGeneratePersonSegmentationRequest()
pReq.qualityLevel = .accurate
try h.perform([pReq])
if let pb = pReq.results?.first?.pixelBuffer {
  var pm = CIImage(cvPixelBuffer: pb)
  pm = pm.transformed(by: CGAffineTransform(scaleX: ext.width / pm.extent.width, y: ext.height / pm.extent.height))
  // ensanchar un poco la mano para no dejar bordes
  let dil = CIFilter.morphologyMaximum(); dil.inputImage = pm; dil.radius = 6
  let pmD = dil.outputImage!.cropped(to: ext)
  let inv = CIFilter.colorInvert(); inv.inputImage = pmD
  let mul = CIFilter.multiplyCompositing(); mul.inputImage = inv.outputImage!; mul.backgroundImage = mask
  mask = mul.outputImage!.cropped(to: ext)
}

// 3) luz y color automáticos sobre la camiseta
var shirt = src
for f in src.autoAdjustmentFilters(options: [.redEye: false]) { f.setValue(shirt, forKey: kCIInputImageKey); if let o = f.outputImage { shirt = o } }
let vib = CIFilter.vibrance(); vib.inputImage = shirt; vib.amount = 0.15; shirt = vib.outputImage!.cropped(to: ext)

// recorte con alfa
let blend = CIFilter.blendWithMask(); blend.inputImage = shirt; blend.backgroundImage = CIImage.empty(); blend.maskImage = mask
let cut = blend.outputImage!.cropped(to: ext)

// caja del contenido (por la máscara)
let cg = ctx.createCGImage(mask, from: ext)!
let w = cg.width, hh = cg.height
var data = [UInt8](repeating: 0, count: w * hh)
let cs = CGColorSpaceCreateDeviceGray()
let bctx = CGContext(data: &data, width: w, height: hh, bitsPerComponent: 8, bytesPerRow: w, space: cs, bitmapInfo: 0)!
bctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: hh))
var minX = w, minY = hh, maxX = 0, maxY = 0
for y in 0..<hh { for x in 0..<w where data[y * w + x] > 40 { if x < minX { minX = x }; if x > maxX { maxX = x }; if y < minY { minY = y }; if y > maxY { maxY = y } } }
// en CGContext la fila 0 es arriba; en CoreImage el origen es abajo
let box = CGRect(x: CGFloat(minX), y: CGFloat(hh - 1 - maxY), width: CGFloat(maxX - minX + 1), height: CGFloat(maxY - minY + 1))

// 4) lienzo parejo 1000x1200 con fondo de vitrina y sombra
let W: CGFloat = 1000, H: CGFloat = 1200, pad: CGFloat = 70
let s = min((W - 2 * pad) / box.width, (H - 2 * pad) / box.height)
let tx = (W - box.width * s) / 2 - box.minX * s, ty = (H - box.height * s) / 2 - box.minY * s
let placed = cut.transformed(by: CGAffineTransform(scaleX: s, y: s).concatenating(CGAffineTransform(translationX: tx, y: ty)))

let canvas = CGRect(x: 0, y: 0, width: W, height: H)
let bg = CIFilter.radialGradient(); bg.center = CGPoint(x: W / 2, y: H * 0.62); bg.radius0 = 40; bg.radius1 = Float(H * 0.75)
bg.color0 = CIColor(red: 0.13, green: 0.15, blue: 0.20); bg.color1 = CIColor(red: 0.035, green: 0.04, blue: 0.055)
let back = bg.outputImage!.cropped(to: canvas)

// sombra: alfa del recorte, oscuro, desenfocado y corrido hacia abajo
let blackShirt = CIFilter.colorMatrix(); blackShirt.inputImage = placed
blackShirt.rVector = CIVector(x: 0, y: 0, z: 0, w: 0); blackShirt.gVector = CIVector(x: 0, y: 0, z: 0, w: 0); blackShirt.bVector = CIVector(x: 0, y: 0, z: 0, w: 0)
blackShirt.aVector = CIVector(x: 0, y: 0, z: 0, w: 0.55)
let sh = blackShirt.outputImage!.transformed(by: CGAffineTransform(translationX: 0, y: -22)).clampedToExtent()
let blur = CIFilter.gaussianBlur(); blur.inputImage = sh; blur.radius = 28
let shadow = blur.outputImage!.cropped(to: canvas)

let out = placed.composited(over: shadow.composited(over: back)).cropped(to: canvas)
try ctx.writeJPEGRepresentation(of: out, to: URL(fileURLWithPath: a[2]), colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!, options: [kCGImageDestinationLossyCompressionQuality as CIImageRepresentationOption: 0.86])
print("ok", Int(box.width), Int(box.height))
