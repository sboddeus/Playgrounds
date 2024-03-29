//
//  AudioPlayerEngine.swift
//  
//  Copyright © 2016-2019 Apple Inc. All rights reserved.
//

import AVFoundation

enum PlayingState {
    case paused
    case playing
    case notPlaying
}

class AudioPlayerEngine {
    // Audio engine used to play the audio.
    private let engine = AVAudioEngine()
    private let tap: AVAudioNodeTapBlock?

    private(set) var playingState: PlayingState = .notPlaying

    /// Synchronizes starting/stopping the engine and scheduling file segments.
    
    private let stateChangeQueue = DispatchQueue(label: "AudioPlayerEngine.StateQueue", attributes: [], target: nil)

    init() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
        } catch {
            fatalError("Can’t set Audio Session category.")
        }
        let _ = engine.mainMixerNode.outputFormat(forBus: 0)
        tap = nil;
    }
    
    init(frameCount: AVAudioFrameCount, tap: @escaping AVAudioNodeTapBlock) {
        self.tap = tap

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        } catch {
            fatalError("Can’t set Audio Session category.")
        }
        let _ = engine.mainMixerNode.outputFormat(forBus: 0)
        let outputFormat = engine.mainMixerNode.outputFormat(forBus: 0)
        let requestedFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: outputFormat.sampleRate , channels: outputFormat.channelCount, interleaved: outputFormat.isInterleaved)
        engine.mainMixerNode.installTap(onBus: 0, bufferSize: frameCount, format: requestedFormat, block: tap)
    }

    
    // MARK: Debug
    
    func mixerNode() -> AVAudioMixerNode {
        return engine.mainMixerNode
    }

    // MARK: Configure the engine
    
    func add(node: AVAudioNode, format: AVAudioFormat, audioUnitEffect: AVAudioUnitEffect? = nil) {
        engine.attach(node)

        if let audioEffect = audioUnitEffect {
            engine.attach(audioEffect)
            engine.connect(node, to: audioEffect, format: format)
            engine.connect(audioEffect, to: engine.mainMixerNode, format: format)
        } else {
            engine.connect(node, to: engine.mainMixerNode, format: format)
        }

    }
    
    func remove(node: AVAudioNode) {
        engine.detach(node)
    }
    
    // MARK: Controlling playback with the engine.
    
    func stop() {
        stateChangeQueue.sync {
            if playingState == .playing {
                engine.stop()
                playingState = .notPlaying
                setActiveForSharedSession(false)
            }
        }
    }
    
    func start() {
        // Start the engine.
        do {
            try engine.start()
            setActiveForSharedSession(true)
        }
        catch {
            fatalError("Could not start engine. Error: \(error).")
        }
    }
    
    private func togglePlay() -> Bool {
        stateChangeQueue.sync {
            if playingState == .playing {
                engine.pause()
                playingState = .paused
            } else {
                if playingState == .notPlaying {
                    setActiveForSharedSession(true)
                }
                // Start the engine.
                playingState = .playing
            }
        }
        
        return playingState == .playing
    }
    
    private func setActiveForSharedSession(_ active: Bool) {
        do {
            try AVAudioSession.sharedInstance().setActive(active)
        } catch {
            fatalError("Could not set Audio Session active \(active). Error: \(error).")
        }
    }    
}
