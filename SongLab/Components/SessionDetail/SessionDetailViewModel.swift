//
//  SessionDetailViewModel.swift
//  SongLab
//
//  Created by Alex Seals on 6/13/24.
//

import Foundation
import Combine
import SwiftUI

@MainActor
class SessionDetailViewModel: ObservableObject {
    
    //MARK: - API
    
    @Published var currentlyPlaying: Session?
    @Published var session: Session
    @Published var progress: Double = 0.0
    
    let audioManager: AudioManager
    var isSessionPlaying: Bool {
        if let currentlyPlaying, currentlyPlaying == session {
            return true
        } else {
            return false
        }
    }
            
    init(recordingManager: RecordingManager, audioManager: AudioManager, session: Session) {
        self.session = session
        self.recordingManager = recordingManager
        self.audioManager = audioManager
        recordingManager.sessions
            .compactMap { $0.first { $0.id == session.id }}
            .assign(to: &$session)
        audioManager.currentlyPlaying
            .assign(to: &$currentlyPlaying)
        audioManager.playerProgress
            .assign(to: &$progress)
        trackVolumeSubject
            .debounce(for: 0.25, scheduler: RunLoop.main)
            .sink { track in
                self.session.tracks[track.id]?.volume = track.volume
                if self.currentlyPlaying != nil {
                    self.currentlyPlaying = self.session
                }
            }
            .store(in: &cancellables)
        
    }
    
    func masterCellSoloButtonTapped() {
        session.isGlobalSoloActive.toggle()
        for track in session.tracks.values {
            if track.soloOverride {
                session.tracks[track.id]?.soloOverride.toggle()
            } else if track.isMuted, track.isSolo, session.isGlobalSoloActive {
                session.tracks[track.id]?.soloOverride.toggle()
            }
        }
        if currentlyPlaying != nil {
            let tracksToToggle = session.tracks.values.filter( { $0.isSolo == false } )
            audioManager.toggleMute(for: tracksToToggle)
            currentlyPlaying = session
        }
    }
    
    func trackCellPlayButtonTapped(for session: Session) {
        do {
            try audioManager.startPlayback(for: session)
        } catch {
            //TODO
        }
    }
    
    func trackCellMuteButtonTapped(for track: Track) {
        session.tracks[track.id]?.isMuted.toggle()
        if track.isMuted {
            session.tracks[track.id]?.soloOverride = false
        }
        if currentlyPlaying != nil {
            if !session.isGlobalSoloActive {
                audioManager.toggleMute(for: Array(arrayLiteral: track))
            }
            currentlyPlaying = session
        }
        
    }
    
    func trackCellSoloButtonTapped(for track: Track) {
        
        if !session.isGlobalSoloActive {
            session.tracks[track.id]?.isSolo = true
            let otherTracks = session.tracks.filter { $0.key != track.id }
            for track in otherTracks.values {
                session.tracks[track.id]?.isSolo = false
            }
            masterCellSoloButtonTapped()
        } else {
            session.tracks[track.id]?.isSolo.toggle()
            let otherSoloTracks = session.tracks.filter { $0.value.isSolo }
            if otherSoloTracks.isEmpty {
                session.isGlobalSoloActive = false
                session.tracks[track.id]?.soloOverride = false
            } else if otherSoloTracks.contains(where: { $0.key == track.id } ), track.isMuted {
                session.tracks[track.id]?.soloOverride = true
            } else {
                session.tracks[track.id]?.soloOverride = false
            }
        }
        
        if currentlyPlaying != nil {
            let tracksToMute = session.tracks.values.filter( { $0.isSolo == false } )
            audioManager.toggleMute(for: tracksToMute)
            currentlyPlaying = session
        }
    }
    
    func trackCellStopButtonTapped() {
        audioManager.stopPlayback()
    }
    
    func trackCellTrashButtonTapped(for track: Track) {
        do {
            try recordingManager.removeTrack(session, track)
        } catch {
            // TODO: Handle Error
        }
    }
    
    func sessionTrashButtonTapped() {
        do {
            try recordingManager.removeSession(session)
        } catch {
            // TODO: Handle Error
        }
    }
    
    func saveSession() {
        do {
            try recordingManager.saveSession(session)
        } catch {
            //TODO
        }
    }
    
    func setTrackVolume(for track: Track, volume: Float) {
        var updatedTrack = track
        updatedTrack.volume = volume
        trackVolumeSubject.send(updatedTrack)
        if currentlyPlaying != nil {
            audioManager.setTrackVolume(for: updatedTrack)
        }
    }
    
    nonisolated func getWaveformImage(for fileName: String, colorScheme: ColorScheme) -> Image {
        do {
            return try audioManager.getImage(for: fileName, colorScheme: colorScheme)
        } catch {}
        return Image(systemName: "waveform")
    }
    
    // MARK: - Variables
    
    private var trackVolumeSubject = PassthroughSubject<Track, Never>()
    private var cancellables = Set<AnyCancellable>()
    private var recordingManager: RecordingManager
    
    
    // MARK: - Functions
}
