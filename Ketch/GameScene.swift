import SpriteKit
import UIKit

final class GameScene: SKScene, SKPhysicsContactDelegate {

    private static let pointValueKey = "pointValue"
    private static let itemTypeKey = "itemType"
    private static let enableGameOverRestartActionKey = "enableGameOverRestart"
    private static let slowMotionPowerUpActionKey = "activeSlowMotionPowerUp"
    private static let scoreMultiplierPowerUpActionKey = "activeScoreMultiplierPowerUp"
    private static let gameOverRestartLockoutDuration: TimeInterval = 1.25
    private static let slowMotionDuration: TimeInterval = 6.0
    private static let scoreMultiplierDuration: TimeInterval = 6.0
    private static let slowedWorldSpeed: CGFloat = 0.55

    private enum PhysicsCategory {
        static let player: UInt32 = 1 << 0
        static let fallingObject: UInt32 = 1 << 1
        static let ground: UInt32 = 1 << 2
    }

    private enum FallingItemType: Int {
        case apple
        case star
        case extraLife
        case slowMotion
        case scoreBoost
        case shield

        var pointValue: Int {
            switch self {
            case .apple:
                return 1
            case .star:
                return 2
            case .extraLife, .slowMotion, .scoreBoost, .shield:
                return 0
            }
        }

        var label: String {
            switch self {
            case .apple:
                return ""
            case .star:
                return ""
            case .extraLife:
                return "Life"
            case .slowMotion:
                return "Slow"
            case .scoreBoost:
                return "x\(GameSessionViewModel.scoreMultiplierValue)"
            case .shield:
                return "Shield"
            }
        }

        var color: UIColor {
            switch self {
            case .apple:
                return .clear
            case .star:
                return .clear
            case .extraLife:
                return .systemGreen
            case .slowMotion:
                return .systemBlue
            case .scoreBoost:
                return .systemOrange
            case .shield:
                return .systemTeal
            }
        }

        static func random() -> FallingItemType {
            let roll = Int.random(in: 0..<100)
            switch roll {
            case 0..<50:
                return .apple
            case 50..<80:
                return .star
            case 80..<90:
                return .extraLife
            case 90..<96:
                return .slowMotion
            case 96..<99:
                return .scoreBoost
            default:
                return .shield
        }
    }
    }

    private let player = SKSpriteNode(imageNamed: "player-basket")
    private let scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private let levelLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private let gameOverLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private let startLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private let shieldIndicator = SKShapeNode(circleOfRadius: 52)
    private var heartNodes: [SKSpriteNode] = []
    private let gameSession = GameSessionViewModel()

    private var isGameOver = false
    private var canRestartAfterGameOver = false
    private var isReadyToStart = true
    private var isRestartingAfterGameOver = false

    private var score: Int { gameSession.score }
    private var level: Int { gameSession.level }
    private var lives: Int { gameSession.lives }
    private var highScore: Int { gameSession.highScore }
    private var isNewHighScore: Bool { gameSession.isNewHighScore }

    override func didMove(to view: SKView) {
        setupScene()
        setupPhysics()
        setupPlayer()
        setupLabels()
        setupStartLabel()
    }

    private func setupScene() {
        backgroundColor = .black
        scaleMode = .resizeFill

        let background = SKSpriteNode(imageNamed: "game-background")
        background.position = CGPoint(x: size.width / 2, y: size.height / 2)
        background.size = size
        background.zPosition = -10
        background.alpha = 0.95

        addChild(background)
    }

    private func setupPhysics() {
        physicsWorld.gravity = CGVector(dx: 0, dy: gravityForCurrentLevel)
        physicsWorld.contactDelegate = self

        let ground = SKNode()
        ground.position = CGPoint(x: size.width / 2, y: 24)
        ground.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: size.width, height: 10))
        ground.physicsBody?.isDynamic = false
        ground.physicsBody?.categoryBitMask = PhysicsCategory.ground
        ground.physicsBody?.contactTestBitMask = PhysicsCategory.fallingObject
        ground.physicsBody?.collisionBitMask = 0

        addChild(ground)
    }

    private func setupPlayer() {
        player.size = CGSize(width: 92, height: 52)
        player.position = CGPoint(x: size.width / 2, y: 90)
        player.zPosition = 5
        player.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 78, height: 34))
        player.physicsBody?.isDynamic = false
        player.physicsBody?.categoryBitMask = PhysicsCategory.player
        player.physicsBody?.contactTestBitMask = PhysicsCategory.fallingObject
        player.physicsBody?.collisionBitMask = 0

        shieldIndicator.fillColor = UIColor.systemTeal.withAlphaComponent(0.12)
        shieldIndicator.strokeColor = UIColor.systemTeal.withAlphaComponent(0.8)
        shieldIndicator.lineWidth = 2
        shieldIndicator.zPosition = 3
        shieldIndicator.isHidden = true
        shieldIndicator.name = "shieldIndicator"
        player.addChild(shieldIndicator)

        addChild(player)
    }

    private func refreshShieldIndicator() {
        let isShielded = gameSession.isShieldPowerUpActive
        shieldIndicator.isHidden = !isShielded
        shieldIndicator.alpha = isShielded ? 1.0 : 0.0
        if isShielded {
            shieldIndicator.removeAllActions()
            let pulse = SKAction.sequence([
                SKAction.fadeAlpha(to: 0.66, duration: 0.8),
                SKAction.fadeAlpha(to: 1.0, duration: 0.8)
            ])
            shieldIndicator.run(SKAction.repeatForever(pulse))
        } else {
            shieldIndicator.removeAllActions()
        }
    }

    private func setupLabels() {
        scoreLabel.fontSize = 28
        scoreLabel.fontColor = .white
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.position = CGPoint(x: 24, y: size.height - 70)
        scoreLabel.zPosition = 10

        addChild(scoreLabel)
        refreshScoreAndLevel()

        setupHearts()
        levelLabel.fontSize = 24
        levelLabel.fontColor = .white
        levelLabel.horizontalAlignmentMode = .center
        levelLabel.position = CGPoint(x: size.width / 2, y: size.height - 108)
        levelLabel.zPosition = 10

        addChild(levelLabel)

        gameOverLabel.fontSize = 36
        gameOverLabel.fontColor = .white
        gameOverLabel.numberOfLines = 5
        gameOverLabel.preferredMaxLayoutWidth = size.width - 48
        gameOverLabel.horizontalAlignmentMode = .center
        gameOverLabel.verticalAlignmentMode = .center
        gameOverLabel.position = CGPoint(x: size.width / 2, y: size.height / 2)
        gameOverLabel.zPosition = 20
        gameOverLabel.isHidden = true
        updateGameOverLabel()

        addChild(gameOverLabel)
    }

    private func setupStartLabel() {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let fontSize: CGFloat = 42
        let font = UIFont(name: "AvenirNext-Bold", size: fontSize)
            ?? UIFont.boldSystemFont(ofSize: fontSize)

        startLabel.attributedText = NSAttributedString(
            string: "Ketch\nHigh Score: \(highScore)\nTap to Start",
            attributes: [
                .font: font,
                .foregroundColor: SKColor.white,
                .paragraphStyle: paragraphStyle
            ]
        )
        startLabel.numberOfLines = 3
        startLabel.preferredMaxLayoutWidth = size.width - 48
        startLabel.horizontalAlignmentMode = .center
        startLabel.verticalAlignmentMode = .center
        startLabel.position = CGPoint(x: size.width / 2, y: size.height / 2)
        startLabel.zPosition = 20
        startLabel.isHidden = false

        addChild(startLabel)

        view?.accessibilityLabel = "Ketch. High Score: \(highScore). Tap to Start"
    }

    private func refreshScoreAndLevel() {
        scoreLabel.text = "Score: \(gameSession.score)"
        levelLabel.text = "Level: \(gameSession.level)"
    }

    private func setupHearts() {
        heartNodes.forEach { $0.removeFromParent() }
        heartNodes.removeAll()

        let heartSize = CGSize(width: 28, height: 28)
        let spacing: CGFloat = 8
        let rightPadding: CGFloat = 24
        let yPosition = size.height - 62

        for index in 0..<3 {
            let heart = SKSpriteNode(imageNamed: "life-heart")
            heart.size = heartSize
            heart.zPosition = 10

            let xOffset = CGFloat(2 - index) * (heartSize.width + spacing)
            heart.position = CGPoint(
                x: size.width - rightPadding - (heartSize.width / 2) - xOffset,
                y: yPosition
            )

            addChild(heart)
            heartNodes.append(heart)
        }

        updateHearts()
    }

    private func updateHearts() {
        for (index, heart) in heartNodes.enumerated() {
            let isFilled = index < lives
            heart.alpha = isFilled ? 1.0 : 0.25
            heart.setScale(isFilled ? 1.0 : 0.86)
        }
    }

    private func startSpawningObjects() {
        let spawn = SKAction.run { [weak self] in
            self?.spawnFallingObject()
        }

        let wait = SKAction.wait(forDuration: spawnDelayForCurrentLevel)
        let sequence = SKAction.sequence([spawn, wait])
        let repeatForever = SKAction.repeatForever(sequence)

        run(repeatForever, withKey: "spawningObjects")
    }

    private func spawnFallingObject() {
        guard !isGameOver, !isReadyToStart else { return }

        let itemType = FallingItemType.random()
        let object = makeFallingObject(for: itemType)
        object.userData = [GameScene.pointValueKey: itemType.pointValue, GameScene.itemTypeKey: itemType.rawValue]

        let randomX = CGFloat.random(in: 40...(size.width - 40))
        object.position = CGPoint(x: randomX, y: size.height + 40)

        object.physicsBody = SKPhysicsBody(circleOfRadius: 20)
        object.physicsBody?.categoryBitMask = PhysicsCategory.fallingObject
        object.physicsBody?.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.ground
        object.physicsBody?.collisionBitMask = 0

        addChild(object)
    }

    private func makeFallingObject(for itemType: FallingItemType) -> SKNode {
        switch itemType {
        case .apple:
            let node = SKSpriteNode(imageNamed: "falling-apple")
            node.size = CGSize(width: 44, height: 44)
            node.zPosition = 4
            return node
        case .star:
            let node = SKSpriteNode(imageNamed: "falling-star")
            node.size = CGSize(width: 44, height: 44)
            node.zPosition = 4
            return node
        case .extraLife, .slowMotion, .scoreBoost, .shield:
            let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
            label.fontSize = 14
            label.text = itemType.label
            label.fontColor = .white
            label.verticalAlignmentMode = .center
            label.horizontalAlignmentMode = .center

            let node = SKShapeNode(circleOfRadius: 22)
            node.fillColor = itemType.color
            node.strokeColor = .white
            node.lineWidth = 2
            node.zPosition = 4
            node.addChild(label)
            node.name = itemType.label

            let badge = SKSpriteNode(imageNamed: "life-heart")
            badge.size = CGSize(width: 12, height: 12)
            badge.position = CGPoint(x: -12, y: 8)
            badge.color = itemType == .extraLife ? .systemGreen : .clear
            badge.colorBlendFactor = itemType == .extraLife ? 1.0 : 0.0
            if itemType == .extraLife {
                node.addChild(badge)
            }

            return node
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }

        if isGameOver {
            guard canRestartAfterGameOver, !isRestartingAfterGameOver else { return }
            restartGame()
            return
        }

        if isReadyToStart {
            startGame()
            return
        }

        let location = touch.location(in: self)
        movePlayer(toX: location.x)
    }

    private func startGame() {
        isReadyToStart = false
        startLabel.isHidden = true
        view?.accessibilityLabel = nil
        startSpawningObjects()
    }

    private func movePlayer(toX xPosition: CGFloat) {
        let halfWidth = player.size.width / 2
        let clampedX = min(max(xPosition, halfWidth), size.width - halfWidth)

        let moveAction = SKAction.moveTo(x: clampedX, duration: 0.16)
        moveAction.timingMode = .easeOut

        player.run(moveAction)
    }

    func didBegin(_ contact: SKPhysicsContact) {
        guard !isGameOver else { return }

        let categories = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask

        if categories == PhysicsCategory.player | PhysicsCategory.fallingObject {
            handleCatch(contact)
        } else if categories == PhysicsCategory.ground | PhysicsCategory.fallingObject {
            handleMiss(contact)
        }
    }

    private func handleCatch(_ contact: SKPhysicsContact) {
        guard let object = fallingObject(from: contact) else { return }
        let catchPosition = object.position
        object.removeFromParent()

        let type = FallingItemType(rawValue: object.userData?[GameScene.itemTypeKey] as? Int ?? 0) ?? .apple
        let basePointValue = object.userData?[GameScene.pointValueKey] as? Int ?? 0
        let catchResult = gameSession.addPoints(for: basePointValue)

        if catchResult.awardedPoints > 0 {
            showPointFeedback(points: catchResult.awardedPoints, at: catchPosition)
        } else {
            applyPowerup(itemType: type, at: catchPosition)
        }

        if catchResult.didLevelUp {
            onLevelUpdated()
        }
        gameSession.updateHighScoreIfNeeded()
        refreshScoreAndLevel()
        showCatchFeedback(at: catchPosition)
        bouncePlayer()
    }

    private func applyPowerup(itemType: FallingItemType, at position: CGPoint) {
        switch itemType {
        case .apple, .star:
            return
        case .extraLife:
            applyExtraLifePowerUp(at: position)
        case .slowMotion:
            applySlowMotionPowerUp(at: position)
        case .scoreBoost:
            applyScoreMultiplierPowerUp(at: position)
        case .shield:
            applyShieldPowerUp(at: position)
        }
    }

    private func applyShieldPowerUp(at position: CGPoint) {
        gameSession.activateShieldPowerUp()
        refreshShieldIndicator()
        showPowerUpFeedback(text: "Shield", at: position, color: .systemTeal)
    }

    private func applyExtraLifePowerUp(at position: CGPoint) {
        let previousLives = lives
        let hadFullLives = gameSession.gainLife()
        let currentLives = lives

        let text = hadFullLives ? "Life Full" : "+1 Life"
        updateHearts()
        if hadFullLives {
            pulseAllHearts()
        } else {
            animateLifeGain(from: previousLives, to: currentLives)
        }
        showPowerUpFeedback(text: text, at: position, color: .systemGreen)
    }

    private func applySlowMotionPowerUp(at position: CGPoint) {
        removeAction(forKey: GameScene.slowMotionPowerUpActionKey)

        gameSession.activateSlowMotionPowerUp()
        physicsWorld.speed = GameScene.slowedWorldSpeed

        let endSlowMotion = SKAction.run { [weak self] in
            self?.physicsWorld.speed = 1.0
            self?.gameSession.deactivateSlowMotionPowerUp()
        }
        run(SKAction.sequence([SKAction.wait(forDuration: GameScene.slowMotionDuration), endSlowMotion]), withKey: GameScene.slowMotionPowerUpActionKey)
        showPowerUpFeedback(text: "Slow Time", at: position, color: .systemBlue)
    }

    private func applyScoreMultiplierPowerUp(at position: CGPoint) {
        removeAction(forKey: GameScene.scoreMultiplierPowerUpActionKey)

        gameSession.activateScoreMultiplierPowerUp()

        let endMultiplier = SKAction.run { [weak self] in
            self?.gameSession.deactivateScoreMultiplierPowerUp()
        }
        run(SKAction.sequence([SKAction.wait(forDuration: GameScene.scoreMultiplierDuration), endMultiplier]), withKey: GameScene.scoreMultiplierPowerUpActionKey)
        showPowerUpFeedback(text: "x\(GameSessionViewModel.scoreMultiplierValue) Score", at: position, color: .systemOrange)
    }

    private func showPowerUpFeedback(text: String, at position: CGPoint, color: UIColor) {
        let feedback = SKLabelNode(fontNamed: "AvenirNext-Bold")
        feedback.text = text
        feedback.fontSize = 20
        feedback.fontColor = color
        feedback.horizontalAlignmentMode = .center
        feedback.position = CGPoint(x: position.x, y: position.y + 28)
        feedback.zPosition = 12
        feedback.alpha = 0

        addChild(feedback)

        let appear = SKAction.fadeIn(withDuration: 0.06)
        let lift = SKAction.moveBy(x: 0, y: 22, duration: 0.24)
        lift.timingMode = .easeOut
        let fade = SKAction.fadeOut(withDuration: 0.2)
        let finish = SKAction.removeFromParent()

        feedback.run(SKAction.sequence([appear, SKAction.group([lift, fade]), finish]))
    }

    private func showCatchFeedback(at position: CGPoint) {
        let sparkle = SKSpriteNode(imageNamed: "sparkle")
        sparkle.position = position
        sparkle.size = CGSize(width: 36, height: 36)
        sparkle.zPosition = 8
        sparkle.alpha = 0
        sparkle.setScale(0.4)

        addChild(sparkle)

        let appear = SKAction.group([
            SKAction.fadeIn(withDuration: 0.06),
            SKAction.scale(to: 1.15, duration: 0.10)
        ])
        let drift = SKAction.moveBy(x: 0, y: 18, duration: 0.18)
        drift.timingMode = .easeOut
        let fade = SKAction.fadeOut(withDuration: 0.18)
        let finish = SKAction.removeFromParent()

        sparkle.run(SKAction.sequence([
            appear,
            SKAction.group([drift, fade]),
            finish
        ]))
    }

    private func showPointFeedback(points: Int, at position: CGPoint) {
        let pointLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        pointLabel.text = "+\(points)"
        pointLabel.fontSize = points > 1 ? 26 : 22
        pointLabel.fontColor = .white
        pointLabel.horizontalAlignmentMode = .center
        pointLabel.position = CGPoint(x: position.x, y: position.y + 28)
        pointLabel.zPosition = 12
        pointLabel.alpha = 0

        addChild(pointLabel)

        let appear = SKAction.fadeIn(withDuration: 0.06)
        let lift = SKAction.moveBy(x: 0, y: 22, duration: 0.24)
        lift.timingMode = .easeOut
        let fade = SKAction.fadeOut(withDuration: 0.18)
        let finish = SKAction.removeFromParent()

        pointLabel.run(SKAction.sequence([
            appear,
            SKAction.group([lift, fade]),
            finish
        ]))
    }

    private func bouncePlayer() {
        player.removeAction(forKey: "catchBounce")
        player.setScale(1.0)

        let squash = SKAction.scaleX(to: 1.08, y: 0.92, duration: 0.06)
        let stretch = SKAction.scaleX(to: 0.96, y: 1.06, duration: 0.07)
        let settle = SKAction.scale(to: 1.0, duration: 0.08)
        let bounce = SKAction.sequence([squash, stretch, settle])

        player.run(bounce, withKey: "catchBounce")
    }

    private var spawnDelayForCurrentLevel: TimeInterval {
        gameSession.spawnDelay(forCurrentLevel: level)
    }

    private var gravityForCurrentLevel: CGFloat {
        gameSession.gravity(forCurrentLevel: level)
    }

    private func onLevelUpdated() {
        refreshScoreAndLevel()
        physicsWorld.gravity = CGVector(dx: 0, dy: gravityForCurrentLevel)
        removeAction(forKey: "spawningObjects")
        startSpawningObjects()
    }

    private func handleMiss(_ contact: SKPhysicsContact) {
        guard let object = fallingObject(from: contact) else { return }
        let missPosition = object.position
        object.removeFromParent()

        let missResult = gameSession.loseLife()
        updateHearts()

        switch missResult {
        case .shielded:
            refreshShieldIndicator()
            showPowerUpFeedback(text: "Shield Saved!", at: missPosition, color: .systemTeal)
            return
        case .gameOver:
            endGame()
            return
        case .lifeLost:
            break
        }

        showMissFeedback(at: missPosition)
        shakeScene()
        pulseLostHeart()
    }

    private func showMissFeedback(at position: CGPoint) {
        let missLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        missLabel.text = "Miss"
        missLabel.fontSize = 22
        missLabel.fontColor = .white
        missLabel.position = CGPoint(x: position.x, y: max(position.y + 28, 54))
        missLabel.zPosition = 12
        missLabel.alpha = 0

        addChild(missLabel)

        let appear = SKAction.fadeIn(withDuration: 0.06)
        let lift = SKAction.moveBy(x: 0, y: 24, duration: 0.28)
        lift.timingMode = .easeOut
        let fade = SKAction.fadeOut(withDuration: 0.22)
        let finish = SKAction.removeFromParent()

        missLabel.run(SKAction.sequence([
            appear,
            SKAction.group([lift, fade]),
            finish
        ]))
    }

    private func shakeScene() {
        removeAction(forKey: "missShake")

        let moveLeft = SKAction.moveBy(x: -8, y: 0, duration: 0.035)
        let moveRight = SKAction.moveBy(x: 16, y: 0, duration: 0.07)
        let settle = SKAction.moveBy(x: -8, y: 0, duration: 0.035)
        let shake = SKAction.sequence([moveLeft, moveRight, settle])

        run(shake, withKey: "missShake")
    }

    private func pulseLostHeart() {
        guard lives >= 0, lives < heartNodes.count else { return }

        let heart = heartNodes[lives]
        heart.removeAction(forKey: "lostHeartPulse")

        let grow = SKAction.scale(to: 1.22, duration: 0.08)
        let shrink = SKAction.scale(to: 0.86, duration: 0.12)
        let pulse = SKAction.sequence([grow, shrink])

        heart.run(pulse, withKey: "lostHeartPulse")
    }

    private func animateLifeGain(from previousLives: Int, to currentLives: Int) {
        guard currentLives > previousLives else { return }
        guard currentLives <= heartNodes.count else { return }

        let gainedHeartIndex = max(0, currentLives - 1)
        let gainedHeart = heartNodes[gainedHeartIndex]
        gainedHeart.removeAction(forKey: "lifeGainPulse")

        let pop = SKAction.sequence([
            SKAction.scale(to: 1.22, duration: 0.09),
            SKAction.scale(to: 0.96, duration: 0.09),
            SKAction.scale(to: 1.0, duration: 0.08)
        ])
        gainedHeart.run(pop, withKey: "lifeGainPulse")
    }

    private func pulseAllHearts() {
        for (index, heart) in heartNodes.enumerated() {
            heart.removeAction(forKey: "lifeGainPulse")
            heart.removeAction(forKey: "fullLifePulse-\(index)")

            let pop = SKAction.sequence([
                SKAction.scale(to: 1.18, duration: 0.08),
                SKAction.scale(to: 0.9, duration: 0.12),
                SKAction.scale(to: 1.0, duration: 0.1)
            ])
            heart.run(pop, withKey: "fullLifePulse-\(index)")
        }
    }

    private func fallingObject(from contact: SKPhysicsContact) -> SKNode? {
        if contact.bodyA.categoryBitMask == PhysicsCategory.fallingObject {
            return contact.bodyA.node
        }

        if contact.bodyB.categoryBitMask == PhysicsCategory.fallingObject {
            return contact.bodyB.node
        }

        return nil
    }

    private func updateGameOverLabel() {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let font = UIFont(name: "AvenirNext-Bold", size: gameOverLabel.fontSize)
            ?? UIFont.boldSystemFont(ofSize: gameOverLabel.fontSize)

        gameOverLabel.attributedText = NSAttributedString(
            string: gameOverResultText,
            attributes: [
                .font: font,
                .foregroundColor: SKColor.white,
                .paragraphStyle: paragraphStyle
            ]
        )
    }

    private var gameOverResultText: String {
        """
        \(isNewHighScore ? "New Best!" : "Game Over")
        Score: \(score)
        Best: \(highScore)
        Level Reached: \(level)
        \(canRestartAfterGameOver ? "Tap to Restart" : "Restart available shortly")
        """
    }

    private func endGame() {
        guard !isGameOver else { return }

        isGameOver = true
        canRestartAfterGameOver = false
        removeAction(forKey: "spawningObjects")
        removeAction(forKey: GameScene.enableGameOverRestartActionKey)
        gameSession.updateHighScoreIfNeeded()
        removeAction(forKey: GameScene.slowMotionPowerUpActionKey)
        removeAction(forKey: GameScene.scoreMultiplierPowerUpActionKey)
        physicsWorld.speed = 1.0
        gameSession.resetPowerUps()
        refreshShieldIndicator()

        updateGameOverLabel()
        gameOverLabel.isHidden = false

        let accessibilityResult = gameOverResultText.replacingOccurrences(of: "\n", with: ". ")
        view?.accessibilityLabel = accessibilityResult
        UIAccessibility.post(notification: .announcement, argument: accessibilityResult)

        let enableRestart = SKAction.run { [weak self] in
            guard let self else { return }

            self.canRestartAfterGameOver = true
            self.updateGameOverLabel()
            self.view?.accessibilityLabel = self.gameOverResultText
                .replacingOccurrences(of: "\n", with: ". ")
        }
        let lockout = SKAction.wait(forDuration: GameScene.gameOverRestartLockoutDuration)
        run(
            SKAction.sequence([lockout, enableRestart]),
            withKey: GameScene.enableGameOverRestartActionKey
        )
    }

    private func restartGame() {
        guard !isRestartingAfterGameOver else { return }
        guard let skView = view else { return }

        isRestartingAfterGameOver = true
        removeAction(forKey: GameScene.enableGameOverRestartActionKey)

        let nextScene = GameScene(size: size)
        nextScene.scaleMode = scaleMode
        DispatchQueue.main.async { [weak skView] in
            skView?.presentScene(nextScene)
        }
    }
}
