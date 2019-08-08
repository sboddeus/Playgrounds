//
//  HelperFunctions.swift
//
//  Copyright © 2017,2018 Apple Inc. All rights reserved.
//

import Foundation
import AVFoundation

var audioController = AudioController()

class AudioController: NSObject, AVAudioPlayerDelegate {
    
    var activeAudioPlayers = Set<AVAudioPlayer>()
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        activeAudioPlayers.remove(player)
    }
    
    func register(_ player: AVAudioPlayer) {
        activeAudioPlayers.insert(player)
        player.delegate = self
    }
}


/// Plays the given sound. Optionally specify a volume from 0 (silent) to 100 (loudest), with 80 being the default.
///
/// - Parameter sound: The sound to be played.
/// - Parameter volume: The volume at which the sound is to be played (0 to 100).
///
/// - localizationKey: playSound(_:volume:)
public func playSound(_ sound: Sound, volume: Int = 80) {
    
    guard let url = sound.url else { return }
    
    do {
        let audioPlayer = try AVAudioPlayer(contentsOf: url)
        audioPlayer.volume = Float(max(min(volume, 100), 0)) / 100.0
        audioController.register(audioPlayer)
        audioPlayer.play()
    } catch {}
}
