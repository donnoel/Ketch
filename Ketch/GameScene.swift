import SpriteKit

final class GameScene: SKScene, SKPhysicsContactDelegate {

    private enum PhysicsCategory {
        static let player: UInt32 = 1 << 0
        static let fallingObject: UInt32 = 1 << 1
        static let ground: UInt32 = 1 << 2
    }

    private let player = SKSpriteNode(color: .systemBlue, size: CGSize(width: 72, height: 32))
    private let scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private let livesLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private let gameOverLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")

    private var score = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)"
        }
    }

    private var lives = 3 {
        didSet {
            livesLabel.text = "Lives: \(lives)"
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
    }

    private func setupPhysics() {
        physicsWorld.gravity = CGVector(dx: 0, dy: -2.5)
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
        player.position = CGPoint(x: size.width / 2, y: 90)
        player.physicsBody = SKPhysicsBody(rectangleOf: player.size)
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

        addChild(scoreLabel)

        livesLabel.text = "Lives: \(lives)"
        livesLabel.fontSize = 28
        livesLabel.fontColor = .white
        livesLabel.horizontalAlignmentMode = .right
        livesLabel.position = CGPoint(x: size.width - 24, y: size.height - 70)

        addChild(livesLabel)

        gameOverLabel.text = "Game Over\nTap to Restart"
        gameOverLabel.fontSize = 36
        gameOverLabel.fontColor = .white
        gameOverLabel.numberOfLines = 2
        gameOverLabel.horizontalAlignmentMode = .center
        gameOverLabel.verticalAlignmentMode = .center
        gameOverLabel.position = CGPoint(x: size.width / 2, y: size.height / 2)
        gameOverLabel.isHidden = true

        addChild(gameOverLabel)
    }

    private func startSpawningObjects() {
        let spawn = SKAction.run { [weak self] in
            self?.spawnFallingObject()
        }

        let wait = SKAction.wait(forDuration: 1.0)
        let sequence = SKAction.sequence([spawn, wait])
        let repeatForever = SKAction.repeatForever(sequence)

        run(repeatForever, withKey: "spawningObjects")
    }

    private func spawnFallingObject() {
        guard !isGameOver else { return }

        let object = SKShapeNode(circleOfRadius: 18)
        object.fillColor = .systemYellow
        object.strokeColor = .clear

        let randomX = CGFloat.random(in: 40...(size.width - 40))
        object.position = CGPoint(x: randomX, y: size.height + 40)

        object.physicsBody = SKPhysicsBody(circleOfRadius: 18)
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
        let object = fallingObject(from: contact)
        object?.removeFromParent()

        score += 1
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
        isGameOver = false

        setupPhysics()
        setupPlayer()
        setupLabels()
        startSpawningObjects()
    }
}
