//
//  HelperFunctions.swift
//  
//  Copyright © 2016-2019 Apple Inc. All rights reserved.
//

import Foundation
import AVFoundation
import PlaygroundSupport

let speech = Speech()

/// Numerical representation for π (~3.14).
///
/// - localizationKey: pi
public var pi = Double.pi

public var pageDifficulty: Difficulty = Difficulty.medium

/// Generates a random Int (whole number) in the given range.
///
/// - Parameter from: The lowest value that the random number can have.
/// - Parameter to: The highest value that the random number can have.
///
/// - localizationKey: randomInt(from:to:)
public func randomInt(from: Int, to: Int) -> Int {
    let maxValue: Int = max(from, to)
    let minValue: Int = min(from, to)
    if minValue == maxValue {
        return minValue
    } else {
        return (Int(arc4random())%(1 + maxValue - minValue)) + minValue
    }
}

/// Generates a random Double (decimal number) in the given range.
///
/// - Parameter from: The lowest value that the random number can have.
/// - Parameter to: The highest value that the random number can have.
///
/// - localizationKey: randomDouble(from:to:)
public func randomDouble(from: Double, to: Double) -> Double {
    let maxValue = max(from, to)
    let minValue = min(from, to)
    if minValue == maxValue {
        return minValue
    } else {
        // Between 0.0 and 1.0
        let randomScaler = Double(arc4random()) / Double(UInt32.max)
        return (randomScaler * (maxValue-minValue)) + minValue
    }
}


/// Speaks the given text.
///
/// - Parameter text: The text to be spoken.
/// - Parameter voice: The voice in which to speak the text. Leave out to use the default voice.
///
/// - localizationKey: speak(_:voice:)
public func speak(_ text: String, voice: SpeechVoice = SpeechVoice()) {
    speech.speak(text, voice: voice)
}

/// Stops any speech that’s currently being spoken.
//
/// - localizationKey: stopSpeaking()
public func stopSpeaking() {
    speech.stopSpeaking()
}

/// Plays the given sound. Optionally, specify a volume from `0` (silent) to `100` (loudest), with `80` being the default.
///
/// - Parameter sound: The sound to be played.
/// - Parameter volume: The volume at which the sound is to be played (ranging from `0` to `100`).
///
/// - localizationKey: playSound(_:volume:)
public func playSound(_ sound: Sound, volume: Int = 80) {
    
    if !AudioSession.current.isPlaybackBlocked && audioController.isSoundEffectsAudioEnabled {
        Message.playSound(sound.rawValue, volume: volume).send()
    }

}

/// Plays the given music. Optionally, specify a volume from `0` (silent) to `100` (loudest), with `80` being the default.
///
/// - Parameter music: The music to be played.
/// - Parameter volume: The volume at which the music is to be played (ranging from `0` to `100`).
///
/// - localizationKey: playMusic(_:volume:)
public func playMusic(_ music: Music, volume: Int = 75) {
    Message.playMusic(music.rawValue, volume: volume).send()
}

/// Plays a note (from `0` to `23`) with the given instrument. Optionally, specify a volume from `0` (silent) to `100` (loudest), with `75` being the default.
///
/// - Parameter instrumentKind: The kind of instrument with which to play the note.
/// - Parameter note: The note to be played (ranging from `0` to `23`).
/// - Parameter volume: The volume at which the note is played (ranging from `0` to `100`).
///
/// - localizationKey: playInstrument(_:note:volume:)
public func playInstrument(_ instrumentKind: Instrument.Kind, note: Double, volume: Double = 75) {
     Message.playInstrument(kind: instrumentKind, note: note, volume: Int(volume)).send()
}

