//
//  Loop.swift
//  
//  Copyright © 2016-2019 Apple Inc. All rights reserved.
//


import Foundation
import AVFoundation

/// Loops support a repeating sound.
///
/// - localizationKey: Loop
public class Loop {
    
    /// The length of the sound loop.
    ///
    /// - localizationKey: Loop.length
    public private(set) var length: Double
    
    /// The sound to play in a loop.
    ///
    /// - localizationKey: Loop.sound
    public private(set) var sound: Sound
    
    /// The volume at which to play the sound.
    ///
    /// - localizationKey: Loop.volume
    public var volume: Double
    
    /// A closure which is called at the beginning of each loop.
    ///
    /// - localizationKey: Loop.loopFireHandler
    public var loopFireHandler: (()->Void)?
    
    /// A property that indicates whether the loop is currently running.
    ///
    /// - localizationKey: Loop.playing
    public private(set) var playing: Bool = false
    
    private var timer: Timer = Timer()
    
    /// Creates a Loop with the given sound and loop fire handler.
    ///
    /// - Parameter sound: The sound to be looped.
    /// - Parameter loopFirehandler: The closure called at the top of each loop.
    ///
    /// - localizationKey: Loop(sound:loopFireHandler)
    public init(sound: Sound, loopFireHandler: (()->Void)? = nil) {
        self.sound = sound
        self.length = 0
        self.volume = 1.0
        self.loopFireHandler = loopFireHandler
        
        if let soundUrl = sound.url {
            do {
                let audioPlayer = try AVAudioPlayer(contentsOf: soundUrl)
                self.length = audioPlayer.duration
            } catch {}
        }
    }

    /// Switches the run state of the Loop, on or off.
    ///
    /// - localizationKey: Loop.toggle
    public func toggle() {
        if playing {
            playing = false
            timer.invalidate()
        } else {
            playing = true
            timer = Timer.scheduledTimer(withTimeInterval: length, repeats: true, block: { timer in
                self.loopFireHandler?()
                
                playSound(self.sound, volume: Int(100.0 * self.volume))
            })
            
            timer.fire()
        }
    }
}
