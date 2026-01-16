import Foundation
import Speech
import AVFoundation

/// Speech recognizer wrapper for in-app voice input
/// Recording only stops when user taps - no automatic timeout
@MainActor
final class SpeechRecognizer: ObservableObject {
    @Published var transcript = ""
    @Published var isRecording = false
    @Published var errorMessage: String?
    
    private var audioEngine: AVAudioEngine?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    
    var onFinalResult: ((String) -> Void)?
    
    /// Request authorization for speech recognition
    func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }
    
    /// Start recording and transcribing
    func startRecording() {
        // Make sure we're not already recording
        guard !isRecording else { return }
        
        guard let recognizer = recognizer, recognizer.isAvailable else {
            errorMessage = "Speech recognition not available"
            return
        }
        
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            audioEngine = AVAudioEngine()
            guard let audioEngine = audioEngine else { return }
            
            request = SFSpeechAudioBufferRecognitionRequest()
            guard let request = request else { return }
            
            // Keep listening without auto-stopping
            request.shouldReportPartialResults = true
            request.addsPunctuation = false
            
            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                self.request?.append(buffer)
            }
            
            audioEngine.prepare()
            try audioEngine.start()
            
            isRecording = true
            transcript = ""
            errorMessage = nil
            
            task = recognizer.recognitionTask(with: request) { [weak self] result, error in
                guard let self = self else { return }
                
                if let result = result {
                    Task { @MainActor in
                        // Update transcript as user speaks
                        self.transcript = result.bestTranscription.formattedString
                        
                        // Only stop if the system says it's truly final (user stopped)
                        // But we DON'T auto-stop - user must tap
                        if result.isFinal && !self.isRecording {
                            self.onFinalResult?(self.transcript)
                        }
                    }
                }
                
                if let error = error {
                    Task { @MainActor in
                        // Ignore cancellation errors (code 216 = cancelled by user)
                        // Ignore "no speech detected" (code 203)
                        let nsError = error as NSError
                        if nsError.code != 216 && nsError.code != 203 && nsError.code != 1110 {
                            self.errorMessage = error.localizedDescription
                        }
                        // Don't auto-stop on error - let user try speaking again
                    }
                }
            }
            
        } catch {
            errorMessage = error.localizedDescription
            stopRecording()
        }
    }
    
    /// Stop recording - only call this when user taps mic
    func stopRecording() {
        guard isRecording else { return }
        
        isRecording = false
        
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.finish() // Use finish() instead of cancel() to get final result
        
        audioEngine = nil
        request = nil
        task = nil
        
        // Deactivate audio session
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
    
    /// Get the current transcript and stop
    func getTranscriptAndStop() -> String {
        let result = transcript
        stopRecording()
        return result
    }
}
