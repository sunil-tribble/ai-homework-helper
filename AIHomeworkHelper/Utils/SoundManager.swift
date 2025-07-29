import AVFoundation
import SwiftUI

/// Manages all sound effects and audio feedback
class SoundManager: ObservableObject {
    static let shared = SoundManager()
    
    @AppStorage("soundEffectsEnabled") private var soundEffectsEnabled = true
    @AppStorage("soundVolume") private var soundVolume: Double = 0.7
    
    private var audioPlayers: [String: AVAudioPlayer] = [:]
    private var systemSoundIDs: [String: SystemSoundID] = [:]
    
    private init() {
        setupAudioSession()
        preloadSounds()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    private func preloadSounds() {
        // System sounds for quick feedback
        systemSoundIDs["tap"] = 1104
        systemSoundIDs["success"] = 1025
        systemSoundIDs["error"] = 1053
        systemSoundIDs["unlock"] = 1003
        
        // Load custom sounds if available
        loadCustomSound("streak_celebration")
        loadCustomSound("badge_unlock")
        loadCustomSound("scan_complete")
        loadCustomSound("points_earned")
        loadCustomSound("level_up")
    }
    
    private func loadCustomSound(_ name: String) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "mp3") else { return }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            player.volume = Float(soundVolume)
            audioPlayers[name] = player
        } catch {
            print("Failed to load sound \(name): \(error)")
        }
    }
    
    // MARK: - Public Methods
    
    func play(_ sound: Sound) {
        guard soundEffectsEnabled else { return }
        
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            switch sound {
            case .tap:
                self?.playSystemSound("tap")
            case .success:
                self?.playSystemSound("success")
            case .error:
                self?.playSystemSound("error")
            case .unlock:
                self?.playSystemSound("unlock")
            case .streakCelebration:
                if self?.playCustomSound("streak_celebration") == nil {
                    self?.playSystemSound("success")
                }
            case .badgeUnlock:
                if self?.playCustomSound("badge_unlock") == nil {
                    self?.playSystemSound("unlock")
                }
            case .scanComplete:
                if self?.playCustomSound("scan_complete") == nil {
                    self?.playSystemSound("success")
                }
            case .pointsEarned:
                if self?.playCustomSound("points_earned") == nil {
                    self?.playSystemSound("tap")
                }
            case .levelUp:
                if self?.playCustomSound("level_up") == nil {
                    self?.playSystemSound("success")
                }
            }
        }
    }
    
    private func playSystemSound(_ name: String) {
        guard let soundID = systemSoundIDs[name] else { return }
        AudioServicesPlaySystemSound(soundID)
    }
    
    private func playCustomSound(_ name: String) -> Bool {
        guard let player = audioPlayers[name] else { return false }
        player.volume = Float(soundVolume)
        player.play()
        return true
    }
    
    func updateVolume(_ volume: Double) {
        soundVolume = volume
        audioPlayers.values.forEach { $0.volume = Float(volume) }
    }
    
    enum Sound {
        case tap
        case success
        case error
        case unlock
        case streakCelebration
        case badgeUnlock
        case scanComplete
        case pointsEarned
        case levelUp
    }
}