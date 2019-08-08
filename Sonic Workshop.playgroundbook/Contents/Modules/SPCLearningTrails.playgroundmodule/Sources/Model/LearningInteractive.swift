//
//  LearningInteractive.swift
//  
//  Copyright © 2016-2019 Apple Inc. All rights reserved.
//

import UIKit
import SPCCore

public class LearningInteractive {
    
    enum Action: String {
        case popupText
    }
    
    enum Direction: String {
        case up, down, left, right
    }
    
    public class Hotspot {
        var position = CGPoint.zero
        var action: Action?
        var direction: Direction?
        var xmlText: String?
        
        init?(xml: String, attributes: [String : String]) {
            guard let posComponents = attributes["position"]?.components(separatedBy: ","), posComponents.count > 1 else { return nil }
            position.x = CGFloat(Float(posComponents[0].trimmingCharacters(in: .whitespaces)) ?? 0)
            position.y = CGFloat(Float(posComponents[1].trimmingCharacters(in: .whitespaces)) ?? 0)
            
            if let actionAttribute = attributes["action"] {
                action = Action(rawValue: actionAttribute)
            }
            
            if let caratDirectionAttribute = attributes["carat"] {
                direction = Direction(rawValue: caratDirectionAttribute)
            }
            
            let parser = SlimXMLParser(xml: xml)
            parser.delegate = self
            parser.parse()
        }
    }
    
    var name: String?
    var hotspots = [Hotspot]()
    var isValid = false
    
    var hotspotData: [(String, [String : String])] = []

    init?(xml: String, attributes: [String : String] = [:]) {
        name = attributes["name"]
        
        let parser = SlimXMLParser(xml: xml)
        parser.delegate = self
        parser.parse()
        parseHotspots() 
        
        if isValid {
            PBLog("LearningInteractive loaded: [\(name ?? "")] with \(hotspots.count) hotspots.")
        } else {
            return nil
        }
    }
    
    private func parseHotspots() {
        hotspotData.forEach( {
            if let hotspot = Hotspot(xml: $0, attributes: $1) {
                hotspots.append(hotspot)
            }
        })

    }
}

extension LearningInteractive: SlimXMLParserDelegate {
    
    func parser(_ parser: SlimXMLParser, didStartElement element: SlimXMLElement) {
        switch element.name {
        case "interactive":
            isValid = true
        default: break
        }
    }
    
    func parser(_ parser: SlimXMLParser, didEndElement element: SlimXMLElement) {
        switch element.name {
        case "hotspot":
            guard let xmlContent = element.xmlContent else { break }
            hotspotData.append((xmlContent, element.attributes))
        default: break
        }
    }
    
    func parser(_ parser: SlimXMLParser, foundCharacters string: String) {
    }
    
    func parser(_ parser: SlimXMLParser, shouldCaptureElementContent elementName: String, attributes: [String : String]) -> Bool {
        switch elementName {
        case "hotspot":
            return true
        default:
            return false
        }
    }
    
    func parser(_ parser: SlimXMLParser, shouldLocalizeElementWithID elementName: String) -> Bool {
        return false
    }
    
    func parser(_ parser: SlimXMLParser, parseErrorOccurred parseError: Error, lineNumber: Int) {
        NSLog("\(parseError.localizedDescription) at line: \(lineNumber)")
    }
}

extension LearningInteractive.Hotspot: SlimXMLParserDelegate {
    
    func parser(_ parser: SlimXMLParser, didStartElement element: SlimXMLElement) {
    }
    
    func parser(_ parser: SlimXMLParser, didEndElement element: SlimXMLElement) {
        switch element.name {
        case "text":
            guard let xmlContent = element.xmlContent else { break }
            self.xmlText = xmlContent
        default:
            break
        }
    }
    
    func parser(_ parser: SlimXMLParser, foundCharacters string: String) {
    }
    
    func parser(_ parser: SlimXMLParser, shouldCaptureElementContent elementName: String, attributes: [String : String]) -> Bool {
        switch elementName {
        case "text":
            return true
        default:
            return false
        }
    }
    
    func parser(_ parser: SlimXMLParser, shouldLocalizeElementWithID elementName: String) -> Bool {
        return true
    }
    
    func parser(_ parser: SlimXMLParser, parseErrorOccurred parseError: Error, lineNumber: Int) {
        NSLog("\(parseError.localizedDescription) at line: \(lineNumber)")
    }
}

