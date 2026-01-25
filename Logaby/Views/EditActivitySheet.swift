import SwiftUI
import SwiftData

/// Sheet for editing any activity type
struct EditActivitySheet: View {
    @Environment(\.dismiss) private var dismiss
    let activity: Activity
    let repository: ActivityRepository
    let onSave: () -> Void
    
    // State for editable fields
    @State private var selectedDate: Date
    @State private var selectedTime: Date
    
    // Feeding fields
    @State private var feedingAmount: String = ""
    @State private var feedingType: FeedingType = .bottle
    @State private var bottleContent: BottleContent = .formula
    @State private var nursingDuration: String = ""
    @State private var nursingSide: NursingSide = .both
    
    // Diaper fields
    @State private var diaperType: DiaperType = .wet
    
    // Sleep fields
    @State private var sleepStartTime: Date = Date()
    @State private var sleepEndTime: Date = Date()
    
    // Weight fields
    @State private var weightLbs: String = ""
    @State private var weightOz: String = ""
    
    // Pumping fields
    @State private var pumpingAmount: String = ""
    @State private var pumpingSide: PumpingSide = .both
    
    init(activity: Activity, repository: ActivityRepository, onSave: @escaping () -> Void) {
        self.activity = activity
        self.repository = repository
        self.onSave = onSave
        
        // Initialize date/time from activity
        _selectedDate = State(initialValue: activity.timestamp)
        _selectedTime = State(initialValue: activity.timestamp)
        
        // Initialize type-specific fields using source
        if let feeding = activity.source as? Feeding {
            _feedingType = State(initialValue: feeding.type)
            _feedingAmount = State(initialValue: feeding.amountOz != nil ? String(format: "%.1f", feeding.amountOz!) : "")
            _bottleContent = State(initialValue: feeding.bottleContent ?? .formula)
            _nursingDuration = State(initialValue: feeding.durationMinutes != nil ? "\(feeding.durationMinutes!)" : "")
            _nursingSide = State(initialValue: feeding.side ?? .both)
        } else if let diaper = activity.source as? Diaper {
            _diaperType = State(initialValue: diaper.type)
        } else if let sleep = activity.source as? Sleep {
            _sleepStartTime = State(initialValue: sleep.startTime)
            _sleepEndTime = State(initialValue: sleep.endTime ?? Date())
        } else if let weight = activity.source as? Weight {
            let lbs = Int(weight.weightLbs)
            let oz = Int((weight.weightLbs - Double(lbs)) * 16)
            _weightLbs = State(initialValue: "\(lbs)")
            _weightOz = State(initialValue: "\(oz)")
        } else if let pumping = activity.source as? Pumping {
            _pumpingAmount = State(initialValue: String(format: "%.1f", pumping.amountOz))
            _pumpingSide = State(initialValue: pumping.side)
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Type-specific fields first (more important)
                if activity.source is Feeding {
                    feedingSection
                } else if activity.source is Diaper {
                    diaperSection
                } else if activity.source is Sleep {
                    sleepSection
                } else if activity.source is Weight {
                    weightSection
                } else if activity.source is Pumping {
                    pumpingSection
                }
                
                // Generic timestamp section (only for non-sleep since sleep has its own)
                if !(activity.source is Sleep) {
                    Section("Date & Time") {
                        DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                        DatePicker("Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                    }
                }
            }
            .navigationTitle("Edit Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveChanges() }
                        .fontWeight(.semibold)
                }
            }
        }
    }
    
    // MARK: - Type-specific Sections
    
    private var feedingSection: some View {
        Section("Feeding Details") {
            Picker("Type", selection: $feedingType) {
                Text("Bottle").tag(FeedingType.bottle)
                Text("Nursing").tag(FeedingType.nursing)
            }
            .pickerStyle(.segmented)
            
            if feedingType == .bottle {
                HStack {
                    Text("Amount")
                    Spacer()
                    TextField("oz", text: $feedingAmount)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                    Text("oz")
                }
                
                Picker("Content", selection: $bottleContent) {
                    Text("Formula").tag(BottleContent.formula)
                    Text("Breastmilk").tag(BottleContent.breastmilk)
                }
            } else {
                HStack {
                    Text("Duration")
                    Spacer()
                    TextField("min", text: $nursingDuration)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                    Text("min")
                }
                
                Picker("Side", selection: $nursingSide) {
                    Text("Both").tag(NursingSide.both)
                    Text("Left").tag(NursingSide.left)
                    Text("Right").tag(NursingSide.right)
                }
            }
        }
    }
    
    private var diaperSection: some View {
        Section("Diaper Type") {
            Picker("Type", selection: $diaperType) {
                Text("Wet 💧").tag(DiaperType.wet)
                Text("Dirty 💩").tag(DiaperType.dirty)
                Text("Both").tag(DiaperType.mixed)
            }
            .pickerStyle(.segmented)
        }
    }
    
    private var sleepSection: some View {
        Section("Sleep Times") {
            DatePicker("Started", selection: $sleepStartTime, displayedComponents: [.date, .hourAndMinute])
            DatePicker("Ended", selection: $sleepEndTime, displayedComponents: [.date, .hourAndMinute])
        }
    }
    
    private var weightSection: some View {
        Section("Weight") {
            HStack {
                TextField("lbs", text: $weightLbs)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 60)
                Text("lbs")
                
                Spacer()
                
                TextField("oz", text: $weightOz)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 60)
                Text("oz")
            }
        }
    }
    
    private var pumpingSection: some View {
        Section("Pumping Details") {
            HStack {
                Text("Amount")
                Spacer()
                TextField("oz", text: $pumpingAmount)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
                Text("oz")
            }
            
            Picker("Side", selection: $pumpingSide) {
                Text("Both").tag(PumpingSide.both)
                Text("Left").tag(PumpingSide.left)
                Text("Right").tag(PumpingSide.right)
            }
        }
    }
    
    // MARK: - Save Logic
    
    private func saveChanges() {
        // Combine date and time
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: selectedTime)
        var combined = DateComponents()
        combined.year = dateComponents.year
        combined.month = dateComponents.month
        combined.day = dateComponents.day
        combined.hour = timeComponents.hour
        combined.minute = timeComponents.minute
        let newTimestamp = calendar.date(from: combined) ?? activity.timestamp
        
        // Update based on type using source
        if let feeding = activity.source as? Feeding {
            feeding.timestamp = newTimestamp
            feeding.type = feedingType
            if feedingType == .bottle {
                feeding.amountOz = Double(feedingAmount) ?? 0
                feeding.bottleContent = bottleContent
                feeding.durationMinutes = nil
                feeding.side = nil
            } else {
                feeding.durationMinutes = Int(nursingDuration) ?? 0
                feeding.side = nursingSide
                feeding.amountOz = nil
                feeding.bottleContent = nil
            }
            repository.updateFeeding(feeding)
        } else if let diaper = activity.source as? Diaper {
            diaper.timestamp = newTimestamp
            diaper.type = diaperType
            repository.updateDiaper(diaper)
        } else if let sleep = activity.source as? Sleep {
            sleep.startTime = sleepStartTime
            sleep.endTime = sleepEndTime
            repository.updateSleep(sleep)
        } else if let weight = activity.source as? Weight {
            weight.timestamp = newTimestamp
            let lbs = Double(weightLbs) ?? 0
            let oz = Double(weightOz) ?? 0
            weight.weightLbs = lbs + (oz / 16.0)
            repository.updateWeight(weight)
        } else if let pumping = activity.source as? Pumping {
            pumping.timestamp = newTimestamp
            pumping.amountOz = Double(pumpingAmount) ?? 0
            pumping.side = pumpingSide
            repository.updatePumping(pumping)
        }
        
        onSave()
        dismiss()
    }
}
