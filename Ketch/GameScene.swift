import SpriteKit

final class GameScene: SKScene, SKPhysicsContactDelegate {

    private enum PhysicsCategory {
        static let player: UInt32 = 1 << 0
        static let fallingObject: UInt32 = 1 << 1
        static let ground: UInt32 = 1 << 2
    }

    private let player = SKSpriteNode(imageNamed: "player-basket")
    private let scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private let levelLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private let gameOverLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
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

    override func didMove(to view: SKView) {
        setupScene()
        setupPhysics()
        setupPlayer()
        setupLabels()
        startSpawningObjects()
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

        gameOverLabel.text = "Game Over\nTap to Restart"
        gameOverLabel.fontSize = 36
        gameOverLabel.fontColor = .white
        gameOverLabel.numberOfLines = 2
        gameOverLabel.horizontalAlignmentMode = .center
        gameOverLabel.verticalAlignmentMode = .center
        gameOverLabel.position = CGPoint(x: size.width / 2, y: size.height / 2)
        gameOverLabel.zPosition = 20
        gameOverLabel.isHidden = true

        addChild(gameOverLabel)
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
        guard !isGameOver else { return }

        let imageName = Bool.random() ? "falling-star" : "falling-apple"
        let object = SKSpriteNode(imageNamed: imageName)
        object.size = CGSize(width: 44, height: 44)
        object.zPosition = 4

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

        let location = touch.location(in: self)
        movePlayer(toX: location.x)
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

        score += 1
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
        let object = fallingObject(from: contact)
        object?.removeFromParent()

        lives -= 1

        if lives <= 0 {
            endGame()
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

    private func endGame() {
        isGameOver = true
        removeAction(forKey: "spawningObjects")
        gameOverLabel.isHidden = false
    }

    private func restartGame() {
        removeAllChildren()
        removeAllActions()

        score = 0
        lives = 3
        level = 1
        isGameOver = false

        setupScene()
        setupPhysics()
        setupPlayer()
        setupLabels()
        startSpawningObjects()
    }
}
