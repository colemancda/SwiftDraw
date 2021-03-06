//
//  CGPath.swift
//  SwiftDraw
//
//  Created by Simon Whitty on 10/3/17.
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

import CoreGraphics
import CoreText
import Foundation
#if os(macOS)
    import AppKit
#elseif os(iOS)
    import UIKit
#endif

extension CGPath {
    func applyA(action: @escaping (CGPathElement)->()) {
        var action = action
        apply(info: &action) {
            let action = $0!.bindMemory(to: ((CGPathElement)->()).self, capacity: 1).pointee
            action($1.pointee)
        }
    }
}

extension CGPath {
    enum Segment {
        case move(CGPoint)
        case line(CGPoint)
        case quad(CGPoint, CGPoint)
        case cubic(CGPoint, CGPoint, CGPoint)
        case close
    }
    
    func segmentsA() -> [Segment] {
        var segments = [Segment]()
        self.applyA {
            let p = $0
            switch (p.type) {
            case .moveToPoint:
                segments.append(Segment.move(p.points[0]))
            case .addLineToPoint:
                segments.append(Segment.line(p.points[0]))
            case .addQuadCurveToPoint:
                segments.append(Segment.quad(p.points[0], p.points[1]))
            case .addCurveToPoint:
                segments.append(Segment.cubic(p.points[0], p.points[1], p.points[2]))
            case .closeSubpath:
                segments.append(Segment.close)
            }
        }
        return segments
    }
}

extension String {
    
    func toPath(font: CTFont) -> CGPath? {
        //kCTFontAttributeName
        let attributes = [NSFontAttributeName as String: font]
        let attString = CFAttributedStringCreate(nil, self as CFString, attributes as CFDictionary)!
        let line = CTLineCreateWithAttributedString(attString)
        let glyphRuns = CTLineGetGlyphRuns(line)
        
        var ascent = CGFloat(0)
        var descent = CGFloat(0)
        var leading = CGFloat(0)
        CTLineGetTypographicBounds(line, &ascent, &descent, &leading)
        let baseline = ascent

        
        let path = CGMutablePath()
        
        for idx in 0..<CFArrayGetCount(glyphRuns) {
            let val = CFArrayGetValueAtIndex(glyphRuns, idx)
            let run = unsafeBitCast(val, to: CTRun.self)
            
            for idx in 0..<CTRunGetGlyphCount(run) {
                let glyphRange = CFRange(location: idx, length: 1)
                var glyph: CGGlyph = 0
                var position: CGPoint = .zero
                CTRunGetGlyphs(run, glyphRange, &glyph)
                CTRunGetPositions(run, glyphRange, &position)
                var t = CGAffineTransform.identity
                if let glyphPath = CTFontCreatePathForGlyph(font, glyph, &t) {
                    let t = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: position.x, ty: baseline)
                    let t1 = t.translatedBy(x: 0, y: baseline)
                    path.addPath(glyphPath, transform: t1)
                }
            }
        }
        
        return path
    }
}
