//
//  AudioRecorder.swift
//  teumsae
//
//  Created by Subeen Park on 2021/11/03.
//

import Foundation
import SwiftUI
import Combine
import AVFoundation


class AudioRecorder: NSObject, ObservableObject {
	
	static let shared = AudioRecorder()
    
    let objectWillChange = PassthroughSubject<AudioRecorder, Never>()
    var audioRecorder: AVAudioRecorder!
    var recordings = [Recording]()
    var recording = false {
            didSet {
                objectWillChange.send(self)
            }
        }
    
    var audioConverter: AudioConverter
    override init() {
        audioConverter = AudioConverter()
        super.init()
        fetchRecordings()
    }
    
    func startRecording() {
        let recordingSession = AVAudioSession.sharedInstance()
        
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
        } catch {
            print("Failed to set up recording session")
        }
        
        let timeStamp = Date()
        let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let relFilePath = "\(timeStamp.toString(dateFormat: "dd-MM-YY_'at'_HH:mm:ss")).wav"
        let audioFilename = documentPath.appendingPathComponent(relFilePath)
        
        
        let settings = [
                    AVFormatIDKey: Int(kAudioFormatLinearPCM),
                    AVSampleRateKey: 12000,
                    AVNumberOfChannelsKey: 1,
                    AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
                ]
        
        print("AUDIO FILE NAME \(audioFilename)")
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder.record()
            recording = true
            PersistenceManager.shared.create(Recording(audioFileName: relFilePath, createdAt: timeStamp))
        } catch {
            print("Could not start recording")
        }
        
    }
    
    func stopRecording() {
        audioRecorder.stop()
        recording = false
        fetchRecordings()
        audioConverter.convertToText(fileURL: (recordings.last?.fileURL) as! URL)
        
        print("\(PersistenceManager.shared.read())") 
    }
    
    func fetchRecordings() {
        recordings.removeAll()
        recordings = PersistenceManager.shared.read()
        recordings.sort(by: { $0.createdAt.compare($1.createdAt) == .orderedAscending})
        objectWillChange.send(self)
    }
    
    func deleteRecording(urlsToDelete: [URL]){
        for url in urlsToDelete{
            print(url)
            do{
//                try FileManager.default.removeItem(at: url)
                PersistenceManager.shared.deleteByFileURL(fileURL: url)
            } catch{
                print("File could not be deleted!")
            }
        }
        
        fetchRecordings()
    }
    
    
    
}
