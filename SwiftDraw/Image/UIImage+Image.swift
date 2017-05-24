//
//  Image+UIImage.swift
//  SwiftDraw
//
//  Created by Simon Whitty on 24/5/17.
//  Copyright 2017 Simon Whitty
//
//  Distributed under the permissive zlib license
//  Get the latest version from here:
//
//  https://github.com/swhitty/SwiftDraw
//
//  This software is provided 'as-is', without any express or implied
//  warranty.  In no event will the authors be held liable for any damages
//  arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,
//  including commercial applications, and to alter it and redistribute it
//  freely, subject to the following restrictions:
//
//  1. The origin of this software must not be misrepresented; you must not
//  claim that you wrote the original software. If you use this software
//  in a product, an acknowledgment in the product documentation would be
//  appreciated but is not required.
//
//  2. Altered source versions must be plainly marked as such, and must not be
//  misrepresented as being the original software.
//
//  3. This notice may not be removed or altered from any source distribution.
//
import UIKit

extension UIImage {
    public class func svgNamed(_ name: String,
                               in bundle: Bundle = Bundle.main) -> UIImage? {
        return Image(named: name, in: bundle)?.rasterize()
    }
}

public extension Image {
    func rasterize() -> UIImage {
        return rasterize(with: size)
    }
    
    func rasterize(with size: CGSize) -> UIImage {
        let f = UIGraphicsImageRendererFormat.default()
        f.opaque = false
        f.prefersExtendedRange = false
        let r = UIGraphicsImageRenderer(size: size, format: f)
        
        let commands = self.commands
        
        return r.image{
            let renderer = CoreGraphicsRenderer(context: $0.cgContext)
            renderer.perform(commands)
        }
    }
}