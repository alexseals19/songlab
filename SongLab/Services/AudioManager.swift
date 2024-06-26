//
//  AudioManager.swift
//  SongLab
//
//  Created by Alex Seals on 6/5/24.
//

import Combine
import Foundation
import AVFoundation
import SwiftUI

struct AudioPlayer {
    var player = AVAudioPlayerNode()
    var track: Track
}

struct AudioPreviewModel: Hashable, Identifiable {
    var magnitude: Float
    var color: Color
    var id = UUID()
}

protocol AudioManager {
    var currentlyPlaying: CurrentValueSubject<Session?, Never> { get }
    var isRecording: CurrentValueSubject<Bool, Never> { get }
    var playerProgress: CurrentValueSubject<Double, Never> { get }
    func startTracking() throws
    func startTracking(for session: Session) throws
    func stopTracking() async
    func stopTracking(for session: Session) async
    func startPlayback(for session: Session) throws
    func stopPlayback()
    func toggleMute(for tracks: [Track])
    func setTrackVolume(for track: Track)
    func getImage(for fileName: String, colorScheme: ColorScheme) throws -> Image
}


class DefaultAudioManager: AudioManager {
    
    // MARK: - API
    
    static let shared = DefaultAudioManager(
        audioSession: AVAudioSession(),
        recorder: AVAudioRecorder(),
        players: [AudioPlayer](),
        metronome: AVAudioPlayerNode(),
        engine: AVAudioEngine(),
        playbackEngine: AVAudioEngine(),
        mixerNode: AVAudioMixerNode(),
        playbackStartTime: Date()
    )
    
    var currentlyPlaying: CurrentValueSubject<Session?, Never>
    var isRecording: CurrentValueSubject<Bool, Never>
    var playerProgress: CurrentValueSubject<Double, Never>
    var subscription: AnyCancellable?
    
    func startTracking() throws {
        try setupRecorder()
        isRecording.send(true)
        recorder.record()
    }
    
    func startTracking(for session: Session) throws {
        let startTime = try setupPlayers(for: session)
        try setupRecorder()
        
        isRecording.send(true)
        currentlyPlaying.send(session)
        
        for player in players {
            player.player.play(at: startTime)
        }
        recorder.record(atTime: CACurrentMediaTime() + 0.5)
        Task {
            await startTimer()
        }
    }
        
    func stopTracking() async {
        
        defer { currentFileName = nil }
        
        Task { @MainActor in
            isRecording.send(false)
        }
        
        recorder.stop()
    
        guard let currentFileName else {
            assertionFailure("currentFileName is nil.")
            return
        }
        
        let url = DataPersistenceManager.createDocumentURL(
            withFileName: currentFileName,
            fileType: .caf
        )
        
        do {
            let audioAsset = AVURLAsset(url: url, options: nil)
            let duration = try await audioAsset.load(.duration)
            let durationInSeconds = CMTimeGetSeconds(duration)
            
            let track = Track(
                name: "Track 1",
                fileName: currentFileName,
                date: Date(),
                length: Double(durationInSeconds),
                id: UUID(),
                volume: 1.0,
                isMuted: false,
                isSolo: false,
                soloOverride: false
            )
            let session = Session(
                name: "Session \(DefaultRecordingManager.shared.absoluteSessionCount + 1)",
                date: Date(),
                length: Double(durationInSeconds),
                tracks: [track.id : track],
                absoluteTrackCount: 1,
                id: UUID(),
                isGlobalSoloActive: false
            )
            try DefaultRecordingManager.shared.saveSession(session)
            DefaultRecordingManager.shared.incrementAbsoluteSessionCount()
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func stopTracking(for session: Session) async {
        defer { currentFileName = nil }
        
        var updatedSession = session
        
        Task { @MainActor in
            isRecording.send(false)
        }
        
        recorder.stop()
        stopPlayback()
        
    
        guard let currentFileName else {
            assertionFailure("currentFileName is nil.")
            return
        }
        
        let url = DataPersistenceManager.createDocumentURL(
            withFileName: currentFileName,
            fileType: .caf
        )
        
        do {
            let audioAsset = AVURLAsset(url: url, options: nil)
            let duration = try await audioAsset.load(.duration)
            let durationInSeconds = CMTimeGetSeconds(duration)
            let name = "Track \(session.absoluteTrackCount + 1)"
            
            let track = Track(
                name: name,
                fileName: currentFileName,
                date: Date(),
                length: Double(durationInSeconds),
                id: UUID(),
                volume: 1.0,
                isMuted: false,
                isSolo: false,
                soloOverride: false
            )
            
            updatedSession.tracks[track.id] = track
            updatedSession.absoluteTrackCount += 1
            
            if track.length > updatedSession.length {
                updatedSession.length = track.length
            }
            
            try DefaultRecordingManager.shared.saveSession(updatedSession)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func startPlayback(for session: Session) throws {
        let startTime = try setupPlayers(for: session)
        
        currentlyPlaying.send(session)
        playerProgress.send(0.0)
        
        for player in players {
            player.player.play(at: startTime)
        }
        
        Task {
            await startTimer()
        }
    }
    
    func stopPlayback() {
        Task { @MainActor in
            currentlyPlaying.send(nil)
        }
        
        for player in players {
            player.player.stop()
        }
        playbackEngine.stop()
        players.removeAll()
        Task {
            await stopProgress()
        }
    }
    
    func toggleMute(for tracks: [Track]) {
        for track in tracks {
            guard let newPlayer = players.first(where: { $0.track.id == track.id }) else {
                return
            }
            if newPlayer.player.volume == 0.0 {
                newPlayer.player.volume = track.volume
            } else {
                newPlayer.player.volume = 0.0
            }
        }
    }
    
    func setTrackVolume(for track: Track) {
        guard let newPlayer = players.first(where: { $0.track.id == track.id }) else {
            return
        }
        newPlayer.player.volume = track.volume
    }
    
    @MainActor func getImage(for fileName: String, colorScheme: ColorScheme) throws -> Image {        
        let samples = try getWaveform(for: fileName)
        
        var color: Color {
            colorScheme == .dark ? .white : .black
        }
        
        let renderer = ImageRenderer(
            content:
                HStack(spacing: 1.0) {
                    ForEach(samples) { sample in
                        Capsule()
                            .frame(width: 1, height: self.normalizeSoundLevel(level: sample.magnitude))
                    }
                    .foregroundStyle(color)
                }
        )
        
        guard let uiImage = renderer.uiImage else  {
            return Image(systemName: "doc")
        }
        
        return Image(uiImage: uiImage)
    }
    
    
    // MARK: - Variables
    
    private var audioSession: AVAudioSession
    private var recorder: AVAudioRecorder
    private var players: [AudioPlayer]
    private var metronome: AVAudioPlayerNode
    private var engine: AVAudioEngine
    private var playbackEngine: AVAudioEngine
    private var mixerNode: AVAudioMixerNode
    private var currentFileName: String?
    private var playbackStartTime: Date
    
    private var bufferInterrupt: Bool = false
    private var beats: [AVAudioPlayerNode] = []
    private var metronomeActive: Bool = true
    private var firstBeat: Bool = true
    private var audioLengthSamples: AVAudioFramePosition = 0
    private var startDate: Date = Date()
    
    private let timer = Timer.publish(every: 0.025, on: .main, in: .common).autoconnect()
    
        
    // MARK: - Functions
    
    private init(
        audioSession: AVAudioSession,
        recorder: AVAudioRecorder,
        players: [AudioPlayer],
        metronome: AVAudioPlayerNode,
        engine: AVAudioEngine,
        playbackEngine: AVAudioEngine,
        mixerNode: AVAudioMixerNode,
        playbackStartTime: Date
    ) {
        currentlyPlaying = CurrentValueSubject(nil)
        isRecording = CurrentValueSubject(false)
        playerProgress = CurrentValueSubject(0.0)
        self.audioSession = audioSession
        self.recorder = recorder
        self.players = players
        self.metronome = metronome
        self.engine = engine
        self.playbackEngine = playbackEngine
        self.mixerNode = mixerNode
        self.playbackStartTime = playbackStartTime
        setUpSession()
        setUpEngine()
        setupNotifications()
    }
    
    private func setUpSession() {
        do {
            audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(
                .playAndRecord,
                options: [.allowBluetoothA2DP, .defaultToSpeaker]
            )
           
            try audioSession.setSupportsMultichannelContent(true)
            try audioSession.setActive(true)
            
            guard let inputs = audioSession.availableInputs else {
                assertionFailure("failed to retrieve inputs")
                return
            }
            try audioSession.setPreferredInput(inputs[0])
        } catch {
            print(error.localizedDescription)
        }
    }
    
    private func setupPlayers(for session: Session) throws -> AVAudioTime {
        let sortedTracks = session.tracks.values.sorted { (lhs: Track, rhs: Track) -> Bool in
            return lhs.length < rhs.length
        }
                
        if currentlyPlaying.value != nil {
            playerProgress.send(0.0)
            for player in players {
                player.player.stop()
                playbackEngine.detach(player.player)
            }
        }
        
        players.removeAll()
        for track in sortedTracks {
            players.append(AudioPlayer(track: track))
        }
        
        let url = DataPersistenceManager.createDocumentURL(
            withFileName: sortedTracks[0].fileName,
            fileType: .caf
        )
        
        let sampleAudioFile = try AVAudioFile(forReading: url)
    
        let sampleRate = sampleAudioFile.processingFormat.sampleRate
    
        for player in players {
            playbackEngine.attach(player.player)
            playbackEngine.connect(player.player,
                                   to: playbackEngine.mainMixerNode,
                                   format: sampleAudioFile.processingFormat)
        }

        playbackEngine.prepare()
        try playbackEngine.start()
        
        let kStartDelayTime = 0.5
        guard let renderTime = players[0].player.lastRenderTime else {
            print("Could not get lastRenderTime")
            return AVAudioTime(hostTime: mach_absolute_time())
        }
        let now: AVAudioFramePosition = renderTime.sampleTime
        
        let sampleTime = AVAudioFramePosition(Double(now) + (kStartDelayTime * sampleRate))
        
        let startTime = AVAudioTime(sampleTime: sampleTime, atRate: sampleRate)
        
        for player in players {
            let url = DataPersistenceManager.createDocumentURL(
                withFileName: player.track.fileName,
                fileType: .caf
            )
            
            let audioFile = try AVAudioFile(forReading: url)
            
            guard let buffer = AVAudioPCMBuffer(
                pcmFormat: audioFile.processingFormat,
                frameCapacity: AVAudioFrameCount(audioFile.length)
            ) else {
                assertionFailure("Could not assign buffer")
                return AVAudioTime(hostTime: mach_absolute_time())
            }
            
            try audioFile.read(into: buffer)

            player.player.scheduleBuffer(buffer,
                                  at: nil,
                                  options: .interrupts,
                                  completionCallbackType: .dataPlayedBack
            ) { _ in
                Task{ @MainActor in
                    if player.player == self.players.last?.player {
                        self.stopPlayback()
                    }
                }
            }
            player.player.prepare(withFrameCount: AVAudioFrameCount(audioFile.length))
        }
        
        if session.isGlobalSoloActive {
            for player in players {
                if player.track.isSolo {
                    if player.track.isMuted, !player.track.soloOverride {
                        player.player.volume = 0.0
                    } else {
                        player.player.volume = player.track.volume
                    }
                } else {
                    player.player.volume = 0.0
                }
            }
        } else {
            for player in players {
                if player.track.isMuted {
                    player.player.volume = 0.0
                } else {
                    player.player.volume = player.track.volume
                }
            }
        }
        
        return startTime
    }
    
    private func setupRecorder() throws {
        currentFileName = "Track\(UUID())"
        
        guard let currentFileName else {
            assertionFailure("currentFileName is nil.")
            return
        }
        
        let url = DataPersistenceManager.createDocumentURL(
            withFileName: currentFileName,
            fileType: .caf
        )
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatAppleLossless),
            AVSampleRateKey: 32000,
            AVNumberOfChannelsKey: 1
        ]
        guard let inputs = audioSession.availableInputs else {
            assertionFailure("inputs")
            return
        }
        try audioSession.setPreferredInput(inputs[0])
        recorder = try AVAudioRecorder(url: url, settings: settings)
        
        recorder.prepareToRecord()
    }
    
    private func setUpEngine() {
        engine = AVAudioEngine()
        mixerNode = AVAudioMixerNode()
        
        mixerNode.volume = 0
        
        engine.attach(mixerNode)
        makeConnections()
    }
    
    private func makeConnections() {
        let inputNode = engine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)
        engine.connect(inputNode, to: mixerNode, format: inputFormat)
        
        let mainMixerNode = engine.mainMixerNode
        let mixerFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: inputFormat.sampleRate,
            channels: 1,
            interleaved: false
        )
        
        engine.connect(mixerNode, to: mainMixerNode, format: mixerFormat)
    }
    
    private func normalizeSoundLevel(level: Float) -> CGFloat {
        let level = max(0.2, CGFloat(level) + 70) / 2
        
        return CGFloat(level * (40/20))
    }
    
    private func getWaveform(for fileName: String) throws -> [AudioPreviewModel] {
        let url = DataPersistenceManager.createDocumentURL(
            withFileName: fileName,
            fileType: .caf
        )
        
        let audioFile = try AVAudioFile(forReading: url)
        
        guard let buffer = AVAudioPCMBuffer(
            pcmFormat: audioFile.processingFormat,
            frameCapacity: AVAudioFrameCount(audioFile.length)
        ) else {
            assertionFailure("Could not assign buffer")
            return []
        }
        
        try audioFile.read(into: buffer)
        
        guard let floatChannelData = buffer.floatChannelData else {
            return []
        }
        
        let frameLength = Int(buffer.frameLength)
        
        let samples = Array(UnsafeBufferPointer(start: floatChannelData[0], count: frameLength))
        
        var result = [AudioPreviewModel]()
        
        let chunked = samples.chunked(into: samples.count / Int(UIScreen.main.bounds.width - 300))
        
        for row in chunked {
            var accumulator: Float = 0
            let newRow = row.map { $0 * $0 }
            accumulator = newRow.reduce(0, +)
            let power: Float = accumulator / Float(row.count)
            let decibles = 10 * log10f(power)
            
            result.append(AudioPreviewModel(magnitude: decibles, color: .gray))
        }
        
        return result
    }
    
    private func startTimer() async {
        do {
            try await Task.sleep(nanoseconds: 425_000_000)
        } catch {}
        startDate = Date()
        subscription = timer.sink { date in
            self.playerProgress.send(date.timeIntervalSince(self.startDate))
        }
    }
    
    private func stopProgress() async {
        do {
            try await Task.sleep(nanoseconds: 200_000_000)
        } catch {}
        subscription?.cancel()
        Task { @MainActor in
            playerProgress.send(0.0)
        }
    }
    
    private func setupNotifications() {
        let nc = NotificationCenter.default
        nc.addObserver(self,
                       selector: #selector(handleRouteChange),
                       name: AVAudioSession.routeChangeNotification,
                       object: nil)
    }

    @objc private func handleRouteChange(notification: Notification) {
        // To be implemented.
        guard let inputs = audioSession.availableInputs else {
            assertionFailure("failed to retrieve inputs")
            return
        }
        do {
            try audioSession.setPreferredInput(inputs[0])
        } catch {
            print(error.localizedDescription)
        }
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
