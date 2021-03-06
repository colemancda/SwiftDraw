//
//  Renderer.swift
//  SwiftDraw
//
//  Created by Simon Whitty on 25/3/17.
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

protocol RendererTypes {
    associatedtype Color
    associatedtype Path
    associatedtype Transform
    associatedtype Float
    associatedtype Point
    associatedtype Rect
    associatedtype BlendMode
    associatedtype FillRule
    associatedtype LineCap
    associatedtype LineJoin
    associatedtype Image
}


protocol RendererTypeProvider {
    associatedtype Types: RendererTypes
    
    func createFloat(from float: Builder.Float) -> Types.Float
    func createPoint(from point: Builder.Point) -> Types.Point
    func createRect(from rect: Builder.Rect) -> Types.Rect
    func createColor(from color: Builder.Color) -> Types.Color
    func createBlendMode(from mode: Builder.BlendMode) -> Types.BlendMode
    func createTransform(from transform: Builder.Transform) -> Types.Transform
    func createPath(from path: Builder.Path) -> Types.Path
    func createPath(from subPaths: [Types.Path]) -> Types.Path
    func createFillRule(from rule: Builder.FillRule) -> Types.FillRule
    func createLineCap(from cap: Builder.LineCap) -> Types.LineCap
    func createLineJoin(from join: Builder.LineJoin) -> Types.LineJoin
    func createImage(from image: Builder.Image) -> Types.Image?
    
    func createEllipse(within rect: Types.Rect) -> Types.Path
    func createLine(from origin: Types.Point, to desination: Types.Point) -> Types.Path
    func createLine(between points: [Types.Point]) -> Types.Path
    func createPolygon(between points: [Types.Point]) -> Types.Path
    func createText(from text: String, with font: String, at origin: Types.Point, ofSize pt: Types.Float) -> Types.Path?
    
    func createRect(from rect: Types.Rect, radii: Builder.Size) -> Types.Path
}

protocol Renderer {
    associatedtype Types: RendererTypes
    
    func pushState()
    func popState()
    func pushTransparencyLayer()
    func popTransparencyLayer()
    
    func concatenate(transform: Types.Transform)
    func translate(tx: Types.Float, ty: Types.Float)
    func rotate(angle: Types.Float)
    func scale(sx: Types.Float, sy: Types.Float)
    
    func setFill(color: Types.Color)
    func setStroke(color: Types.Color)
    func setLine(width: Types.Float)
    func setLine(cap: Types.LineCap)
    func setLine(join: Types.LineJoin)
    func setLine(miterLimit: Types.Float)
    func setClip(path: Types.Path)
    func setBlend(mode: Types.BlendMode)
    
    func stroke(path: Types.Path)
    func fill(path: Types.Path, rule: Types.FillRule)
    func draw(image: Types.Image)
}

extension Renderer {
    func perform(_ command: RendererCommand<Types>) {
        switch command {
        case .pushState:
            pushState()
        case .popState:
            popState()
        case .concatenate(transform: let t):
            concatenate(transform: t)
        case .translate(tx: let x, ty: let y):
            translate(tx: x, ty: y)
        case .scale(sx: let x, sy: let y):
            scale(sx: x, sy: y)
        case .rotate(angle: let a):
            rotate(angle: a)
        case .setFill(color: let c):
            setFill(color: c)
        case .setStroke(color: let c):
            setStroke(color: c)
        case .setLine(width: let w):
            setLine(width: w)
        case .setLineCap(let c):
            setLine(cap: c)
        case .setLineJoin(let j):
            setLine(join: j)
        case .setLineMiter(limit: let l):
            setLine(miterLimit: l)
        case .setClip(path: let p):
            setClip(path: p)
        case .setBlend(mode: let m):
            setBlend(mode: m)
        case .stroke(let p):
            stroke(path: p)
        case .fill(let p, let r):
            fill(path: p, rule: r)
        case .draw(image: let i):
            draw(image: i)
        case .pushTransparencyLayer:
            pushTransparencyLayer()
        case .popTransparencyLayer:
            popTransparencyLayer()
        }
    }
    
    func perform(_ commands: [RendererCommand<Types>]) {
        for cmd in commands {
            perform(cmd)
        }
    }
}

enum RendererCommand<Types: RendererTypes> {
    case pushState
    case popState
    
    case concatenate(transform: Types.Transform)
    case translate(tx: Types.Float, ty: Types.Float)
    case rotate(angle: Types.Float)
    case scale(sx: Types.Float, sy: Types.Float)

    case setFill(color: Types.Color)
    case setStroke(color: Types.Color)
    case setLine(width: Types.Float)
    case setLineCap(Types.LineCap)
    case setLineJoin(Types.LineJoin)
    case setLineMiter(limit: Types.Float)
    case setClip(path: Types.Path)
    case setBlend(mode: Types.BlendMode)
    
    case stroke(Types.Path)
    case fill(Types.Path, rule: Types.FillRule)
    
    case draw(image: Types.Image)
    
    case pushTransparencyLayer
    case popTransparencyLayer
}
