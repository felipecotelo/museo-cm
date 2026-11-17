// Recorta la camiseta del fondo con Vision (recorte de sujeto de macOS).
// Uso: swift tools/recortar.swift entrada.jpg salida.png
import Foundation
import Vision
import CoreImage
import ImageIO
import UniformTypeIdentifiers

let args = CommandLine.arguments
guard args.count == 3 else { print("uso: recortar entrada salida.png"); exit(2) }
let url = URL(fileURLWithPath: args[1])
guard let src = CGImageSourceCreateWithURL(url as CFURL, nil),
      let cg = CGImageSourceCreateImageAtIndex(src, 0, nil) else { print("no se pudo leer"); exit(1) }

let req = VNGenerateForegroundInstanceMaskRequest()
let handler = VNImageRequestHandler(cgImage: cg, options: [:])
do {
  try handler.perform([req])
  guard let obs = req.results?.first else { print("sin sujeto"); exit(1) }
  let buf = try obs.generateMaskedImage(ofInstances: obs.allInstances, from: handler, croppedToInstancesExtent: true)
  let ci = CIImage(cvPixelBuffer: buf)
  let ctx = CIContext()
  guard let out = ctx.createCGImage(ci, from: ci.extent) else { exit(1) }
  let dest = CGImageDestinationCreateWithURL(URL(fileURLWithPath: args[2]) as CFURL, UTType.png.identifier as CFString, 1, nil)!
  CGImageDestinationAddImage(dest, out, nil)
  CGImageDestinationFinalize(dest)
  print("ok", out.width, out.height)
} catch { print("error", error); exit(1) }
