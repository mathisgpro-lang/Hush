import Foundation

/// Opt-in camera verification; no quests, purchases, day advancement or journey resets.
@MainActor func runFramingCheck(_ model: ShellModel) async {
    while !model.coreReady { try? await Task.sleep(for: .milliseconds(200)) }
    let realms: [RealmID] = [.sanctuary, .grove, .stillwater, .highlands, .forge, .library, .wilds]
    let poses: [(String, SIMD2<Float>)] = [
        ("rest", .zero), ("left-up", [-9, 9]), ("right-up", [9, 9]),
        ("left-down", [-9, -9]), ("right-down", [9, -9])
    ]
    for realm in realms {
        await model.ensure(realm == .sanctuary ? .sanctuary : .realm(realm))
        model.screen = realm == .sanctuary ? .home : .realm(realm)
        model.showActive()
        try? await Task.sleep(for: .seconds(4))
        let scene: any LivingWorld = realm == .sanctuary ? model.sanctuary : model.realmScene(realm)
        for (pose, target) in poses {
            scene.panTarget = target
            try? await Task.sleep(for: .seconds(2))
            let ack = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("framing-next")
            try? FileManager.default.removeItem(at: ack)
            let line = "FRAME_CAPTURE \(realm.rawValue) \(pose) limits \(scene.panLimit.x) \(scene.panLimit.y)\n"
            FileHandle.standardOutput.write(Data(line.utf8))
            for _ in 0..<600 {
                if FileManager.default.fileExists(atPath: ack.path) { break }
                try? await Task.sleep(for: .milliseconds(100))
            }
        }
        scene.panTarget = .zero
    }
    model.screen = .home
    model.showActive()
    FileHandle.standardOutput.write(Data("FRAMING_CHECK_DONE\n".utf8))
}
