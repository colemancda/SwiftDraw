//
//  Parser.XML.Element.swift
//  SwiftDraw
//
//  Created by Simon Whitty on 31/12/16.
//  Copyright 2016 Simon Whitty
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

extension XMLParser {
    
    func parseLine(_ att: AttributeParser) throws -> DOM.Line {
        let x1: DOM.Coordinate = try att.parseCoordinate("x1")
        let y1: DOM.Coordinate = try att.parseCoordinate("y1")
        let x2: DOM.Coordinate = try att.parseCoordinate("x2")
        let y2: DOM.Coordinate = try att.parseCoordinate("y2")
        return DOM.Line(x1: x1, y1: y1, x2: x2, y2: y2)
    }
    
    func parseCircle(_ att: AttributeParser) throws -> DOM.Circle {
        let cx: DOM.Coordinate = try att.parseCoordinate("cx")
        let cy: DOM.Coordinate = try att.parseCoordinate("cy")
        let r: DOM.Coordinate = try att.parseCoordinate("r")
        return DOM.Circle(cx: cx, cy: cy, r: r)
    }
    
    func parseEllipse(_ att: AttributeParser) throws -> DOM.Ellipse {
        let cx: DOM.Coordinate = try att.parseCoordinate("cx")
        let cy: DOM.Coordinate = try att.parseCoordinate("cy")
        let rx: DOM.Coordinate = try att.parseCoordinate("rx")
        let ry: DOM.Coordinate = try att.parseCoordinate("ry")
        return DOM.Ellipse(cx: cx, cy: cy, rx: rx, ry: ry)
    }
    
    func parseRect(_ att: AttributeParser) throws -> DOM.Rect {
 
        let width: DOM.Coordinate = try att.parseCoordinate("width")
        let height: DOM.Coordinate = try att.parseCoordinate("height")
        let rect = DOM.Rect(width: width, height: height)
        
        rect.x = try att.parseCoordinate("x")
        rect.y = try att.parseCoordinate("y")
        rect.rx = try att.parseCoordinate("rx")
        rect.ry = try att.parseCoordinate("ry")
        
        return rect
    }
    
    func parsePoints(_ text: String) -> [DOM.Point] {
        var points = Array<DOM.Point>()
        var scanner = Scanner(text: text)
        
        while let x = try? scanner.scanCoordinate(),
            let y = try? scanner.scanCoordinate() {
            points.append(DOM.Point(x, y))
        }
        
        return points
    }
    
    func parsePolyline(_ att: AttributeParser) throws -> DOM.Polyline {
        return DOM.Polyline(points: try att.parsePoints("points"))
    }
    
    func parsePolygon(_ att: AttributeParser) throws -> DOM.Polygon {
        return DOM.Polygon(points: try att.parsePoints("points"))
    }
    
    func parseGraphicsElement(_ e: XML.Element) throws -> DOM.GraphicsElement? {
        
        var ge: DOM.GraphicsElement
        
        let att = try parseAttributes(e)
   
        switch e.name {
        case "g": ge = try parseGroup(e)
        case "line": ge = try parseLine(att)
        case "circle": ge = try parseCircle(att)
        case "ellipse": ge = try parseEllipse(att)
        case "rect": ge = try parseRect(att)
        case "polyline": ge = try parsePolyline(att)
        case "polygon": ge = try parsePolygon(att)
        case "path": ge = try parsePath(att)
        case "text":
            guard let text = try parseText(att, element: e) else { return nil }
            ge = text
        case "use": ge = try parseUse(att)
        case "switch": ge = try parseSwitch(e)
        case "image": ge = try parseImage(att)
        default: return nil
        }
        
        ge.id = e.attributes["id"]
        
        let presentation = try parsePresentationAttributes(att)
        ge.updateAttributes(from: presentation)
        
        return ge
    }

    
    func parseContainerChildren(_ e: XML.Element) throws -> [DOM.GraphicsElement] {
        guard e.name == "svg" ||
              e.name == "clipPath" ||
              e.name == "mask" ||
              e.name == "defs" ||
              e.name == "switch" ||
              e.name == "g" else {
            throw Error.invalid
        }
        
        var children = Array<DOM.GraphicsElement>()
        
        for n in e.children {
            do {
                if let ge = try parseGraphicsElement(n) {
                    children.append(ge)
                }
            } catch XMLParser.Error.invalidElement(let e)  {
                guard options.contains(.skipInvalidElements) else {
                    throw Error.invalidElement(name: e.name,
                                               error: e.error,
                                               line: e.line,
                                               column: e.column)
                }

            } catch let error {
                guard options.contains(.skipInvalidElements) else {
                    throw Error.invalidElement(name: n.name,
                                                   error: error,
                                                   line: n.parsedLocation?.line,
                                                   column: n.parsedLocation?.column)
                }
            }
        }
        
        return children
    }
    
    func parseGroup(_ e: XML.Element) throws -> DOM.Group {
        guard e.name == "g" else {
            throw Error.invalid
        }
        
        let group = DOM.Group()
        group.childElements = try parseContainerChildren(e)
        return group
    }
    
    func parseSwitch(_ e: XML.Element) throws -> DOM.Switch {
        guard e.name == "switch" else {
            throw Error.invalid
        }
        
        let node = DOM.Switch()
        node.childElements = try parseContainerChildren(e)
        return node
    }
    
    func parseAttributes(_ e: XML.Element) throws -> Attributes {
        guard let styleText = e.attributes["style"] else {
            return Attributes(parser: ValueParser(),
                              options: options,
                              element: e.attributes,
                              style: [:])
        }
        
        var scanner = Scanner(text: styleText)
        var style = [String: String]()
        
        while !scanner.isEOF {
            let att = try parseStyleAttribute(&scanner)
            style[att.0] = att.1
        }
        
        var element = e.attributes
        element["style"] = nil
        return Attributes(parser: ValueParser(),
                          options: options,
                          element: element,
                          style: style)
    }
    
    func parseStyleAttribute(_ scanner: inout Scanner) throws -> (String, String) {
        guard let key = scanner.scan(upTo: " \t:") else {
            throw Error.invalid
        }
        _ = scanner.scan(":")
        
        if let value = scanner.scan(upTo: ";") {
            _ = scanner.scan(";")
            return (key, value.trimmingCharacters(in: .whitespaces))
        }
        
        guard let value = scanner.scanToEOF() else {
            throw Error.invalid
        }
        
        return (key, value.trimmingCharacters(in: .whitespaces))
    }
    
    func parsePresentationAttributes(_ att: AttributeParser) throws -> PresentationAttributes {
        let el = DOM.GraphicsElement()

        el.opacity = try att.parsePercentage("opacity")
        el.display = try att.parseRaw("display")
        
        el.stroke = try att.parseColor("stroke")
        el.strokeWidth = try att.parseFloat("stroke-width")
        el.strokeOpacity = try att.parsePercentage("stroke-opacity")
        el.strokeLineCap = try att.parseRaw("stroke-linecap")
        el.strokeLineJoin = try att.parseRaw("stroke-linejoin")
        
        //maybe handle this better
        // att.parseDashArray?
        if let dash = try att.parseString("stroke-dasharray") as String?,
           dash.trimmingCharacters(in: .whitespaces) == "none" {
            el.strokeDashArray = nil
        } else {
            el.strokeDashArray = try att.parseFloats("stroke-dasharray")
        }
        
        el.fill = try att.parseColor("fill")
        el.fillOpacity = try att.parsePercentage("fill-opacity")
        el.fillRule = try att.parseRaw("fill-rule")
        
        if let val = try? att.parseString("transform") {
            el.transform = try parseTransform(val)
        }
      
        el.clipPath = try att.parseUrlSelector("clip-path")
        el.mask = try att.parseUrlSelector("mask")

        return el
    }
    
    
}


extension PresentationAttributes {
    
    mutating func updateAttributes(from attributes: PresentationAttributes) {
        opacity = attributes.opacity
        display = attributes.display
        stroke = attributes.stroke
        strokeWidth = attributes.strokeWidth
        strokeOpacity = attributes.strokeOpacity
        fill = attributes.fill
        fillOpacity = attributes.fillOpacity
        fillRule = attributes.fillRule
        transform = attributes.transform
        clipPath = attributes.clipPath
        mask = attributes.mask
    }
    
}
