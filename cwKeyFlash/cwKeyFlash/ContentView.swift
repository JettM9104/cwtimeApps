import SwiftUI
import AVFoundation

struct ContentView: View {
    @State private var inputText = ""
    @State private var isFlashing = false
    @State private var isTorchOn = false // <-- New state to track torch status

    let morseCodeMap: [Character: String] = [
        "A": ".-", "B": "-...", "C": "-.-.", "D": "-..", "E": ".",
        "F": "..-.", "G": "--.", "H": "....", "I": "..", "J": ".---",
        "K": "-.-", "L": ".-..", "M": "--", "N": "-.", "O": "---",
        "P": ".--.", "Q": "--.-", "R": ".-.", "S": "...", "T": "-",
        "U": "..-", "V": "...-", "W": ".--", "X": "-..-", "Y": "-.--",
        "Z": "--..",
        "0": "-----", "1": ".----", "2": "..---", "3": "...--",
        "4": "....-", "5": ".....", "6": "-....", "7": "--...",
        "8": "---..", "9": "----."
    ]

    var body: some View {
        VStack(spacing: 20) {
            // Torch status box
            HStack {
                Circle()
                    .fill(isTorchOn ? Color.green : Color.red)
                    .frame(width: 15, height: 15)
                Text(isTorchOn ? "Torch ON" : "Torch OFF")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(8)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.top)

            TextField("Enter text", text: $inputText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button(action: {
                Task {
                    await flashMorseCode(for: inputText)
                }
            }) {
                Text("Flash Morse Code")
                    .padding()
                    .background(isFlashing ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(isFlashing)
        }
        .padding()
    }

    func flashMorseCode(for text: String) async {
        isFlashing = true
        let unit: UInt64 = 100_000_000 // 100 ms

        let words = text.uppercased().split(separator: " ")
        for (wordIndex, word) in words.enumerated() {
            for (letterIndex, char) in word.enumerated() {
                guard let morse = morseCodeMap[char] else { continue }

                for (symbolIndex, symbol) in morse.enumerated() {
                    // Flash light for dot or dash
                    toggleTorch(on: true)
                    try? await Task.sleep(nanoseconds: symbol == "." ? unit : unit * 3)
                    toggleTorch(on: false)

                    // Pause between symbols
                    if symbolIndex < morse.count - 1 {
                        try? await Task.sleep(nanoseconds: unit)
                    }
                }

                // Pause between letters
                if letterIndex < word.count - 1 {
                    try? await Task.sleep(nanoseconds: unit * 3)
                }
            }

            // Pause between words
            if wordIndex < words.count - 1 {
                try? await Task.sleep(nanoseconds: unit * 7)
            }
        }

        toggleTorch(on: false)
        isFlashing = false
    }

    func toggleTorch(on: Bool) {
        guard let device = AVCaptureDevice.default(for: .video),
              device.hasTorch else { return }

        do {
            try device.lockForConfiguration()
            if on {
                try device.setTorchModeOn(level: 1.0)
            } else {
                device.torchMode = .off
            }
            isTorchOn = on // <-- Update torch status
            device.unlockForConfiguration()
        } catch {
            print("Torch error: \(error)")
        }
    }
}
