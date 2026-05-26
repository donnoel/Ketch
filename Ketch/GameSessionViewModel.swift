import Foundation

struct PointCatchResult {
    let awardedPoints: Int
    let didLevelUp: Bool
}

enum MissResult {
    case shielded
    case lifeLost
    case gameOver
}

final class GameSessionViewModel {
    private static let highScoreKey = "Ketch.highScore"
    static let scoreMultiplierValue = 2

    private(set) var score = 0
    private(set) var level = 1
    private(set) var lives = 3
    private(set) var highScore = UserDefaults.standard.integer(forKey: GameSessionViewModel.highScoreKey)
    private(set) var isNewHighScore = false
    private(set) var scoreMultiplier = 1
    private(set) var isSlowMotionPowerUpActive = false
    private(set) var isScoreMultiplierActive = false
    private(set) var isShieldPowerUpActive = false

    private let maxLives = 3

    @discardableResult
    func addPoints(for basePointValue: Int) -> PointCatchResult {
        guard basePointValue > 0 else {
            return PointCatchResult(awardedPoints: 0, didLevelUp: false)
        }

        let awardedPoints = basePointValue * scoreMultiplier
        let previousLevel = level

        score += awardedPoints

        level = (score / 5) + 1
        let didLevelUp = level != previousLevel

        return PointCatchResult(awardedPoints: awardedPoints, didLevelUp: didLevelUp)
    }

    @discardableResult
    func loseLife() -> MissResult {
        if isShieldPowerUpActive {
            isShieldPowerUpActive = false
            return .shielded
        }

        lives -= 1
        return lives <= 0 ? .gameOver : .lifeLost
    }

    @discardableResult
    func gainLife() -> Bool {
        let hadFullLives = lives >= maxLives
        if !hadFullLives {
            lives += 1
        }
        return hadFullLives
    }

    func updateHighScoreIfNeeded() {
        guard score > highScore else { return }

        highScore = score
        isNewHighScore = true
        UserDefaults.standard.set(highScore, forKey: Self.highScoreKey)
    }

    func activateSlowMotionPowerUp() {
        isSlowMotionPowerUpActive = true
    }

    func deactivateSlowMotionPowerUp() {
        isSlowMotionPowerUpActive = false
    }

    func activateScoreMultiplierPowerUp() {
        isScoreMultiplierActive = true
        scoreMultiplier = Self.scoreMultiplierValue
    }

    func activateShieldPowerUp() {
        isShieldPowerUpActive = true
    }

    func deactivateScoreMultiplierPowerUp() {
        isScoreMultiplierActive = false
        scoreMultiplier = 1
    }

    func deactivateShieldPowerUp() {
        isShieldPowerUpActive = false
    }

    func resetPowerUps() {
        deactivateSlowMotionPowerUp()
        deactivateScoreMultiplierPowerUp()
        deactivateShieldPowerUp()
    }

    func resetGameState() {
        score = 0
        level = 1
        lives = maxLives
        isNewHighScore = false
        resetPowerUps()
    }

    func spawnDelay(forCurrentLevel level: Int) -> TimeInterval {
        max(0.35, 1.0 - (Double(level - 1) * 0.08))
    }

    func gravity(forCurrentLevel level: Int) -> CGFloat {
        -2.5 - (CGFloat(level - 1) * 0.35)
    }
}
