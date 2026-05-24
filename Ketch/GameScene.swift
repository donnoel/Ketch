import SpriteKit
import UIKit

final class GameScene: SKScene, SKPhysicsContactDelegate {

    private static let highScoreKey = "Ketch.highScore"
    private static let pointValueKey = "pointValue"

    private enum PhysicsCategory {
        static let player: UInt32 = 1 << 0
        static let fallingObject: UInt32 = 1 << 1
        static let ground: UInt32 = 1 << 2
    }

    private let player = SKSpriteNode(imageNamed: "player-basket")
    private let scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private let levelLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private let gameOverLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private let startLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private var heartNodes: [SKSpriteNode] = []

    private var score = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)"
        }
    }

    private var lives = 3 {
        didSet {
            updateHearts()
        }
    }

    private var level = 1 {
        didSet {
            levelLabel.text = "Level: \(level)"
        }
    }

    private var isGameOver = false
    private var isReadyToStart = true
    private var highScore = UserDefaults.standard.integer(forKey: GameScene.highScoreKey)
    private var isNewHighScore = false

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

        addChild(player)
    }

    private func setupLabels() {
        scoreLabel.text = "Score: \(score)"
        scoreLabel.fontSize = 28
        scoreLabel.fontColor = .white
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.position = CGPoint(x: 24, y: size.height - 70)
        scoreLabel.zPosition = 10

        addChild(scoreLabel)

        setupHearts()

        levelLabel.text = "Level: \(level)"
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

        let isStar = Bool.random()
        let imageName = isStar ? "falling-star" : "falling-apple"
        let pointValue = isStar ? 2 : 1
        let object = SKSpriteNode(imageNamed: imageName)
        object.size = CGSize(width: 44, height: 44)
        object.zPosition = 4
        object.userData = [GameScene.pointValueKey: pointValue]

        let randomX = CGFloat.random(in: 40...(size.width - 40))
        object.position = CGPoint(x: randomX, y: size.height + 40)

        object.physicsBody = SKPhysicsBody(circleOfRadius: 20)
        object.physicsBody?.categoryBitMask = PhysicsCategory.fallingObject
        object.physicsBody?.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.ground
        object.physicsBody?.collisionBitMask = 0

        addChild(object)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }

        if isGameOver {
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

        let pointValue = object.userData?[GameScene.pointValueKey] as? Int ?? 1
        score += pointValue
        updateLevelIfNeeded()
        showCatchFeedback(at: catchPosition)
        bouncePlayer()
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
        max(0.35, 1.0 - (Double(level - 1) * 0.08))
    }

    private var gravityForCurrentLevel: CGFloat {
        -2.5 - (CGFloat(level - 1) * 0.35)
    }

    private func updateLevelIfNeeded() {
        let newLevel = (score / 5) + 1
        guard newLevel != level else { return }

        level = newLevel
        physicsWorld.gravity = CGVector(dx: 0, dy: gravityForCurrentLevel)
        removeAction(forKey: "spawningObjects")
        startSpawningObjects()
    }

    private func handleMiss(_ contact: SKPhysicsContact) {
        guard let object = fallingObject(from: contact) else { return }
        let missPosition = object.position
        object.removeFromParent()

        lives -= 1
        showMissFeedback(at: missPosition)
        shakeScene()
        pulseLostHeart()

        if lives <= 0 {
            endGame()
        }
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
        Tap to Restart
        """
    }

    private func endGame() {
        isGameOver = true
        removeAction(forKey: "spawningObjects")

        if score > highScore {
            highScore = score
            isNewHighScore = true
            UserDefaults.standard.set(highScore, forKey: GameScene.highScoreKey)
        }

        updateGameOverLabel()
        gameOverLabel.isHidden = false

        let accessibilityResult = gameOverResultText.replacingOccurrences(of: "\n", with: ". ")
        view?.accessibilityLabel = accessibilityResult
        UIAccessibility.post(notification: .announcement, argument: accessibilityResult)
    }

    private func restartGame() {
        removeAllChildren()
        removeAllActions()
        view?.accessibilityLabel = nil

        score = 0
        lives = 3
        level = 1
        isGameOver = false
        isReadyToStart = true
        isNewHighScore = false

        setupScene()
        setupPhysics()
        setupPlayer()
        setupLabels()
        setupStartLabel()
    }
}
